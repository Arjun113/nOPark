#!/bin/bash

set -e

IMPORT_MODE=${OSM_IMPORT_MODE:-raw}

# Download if does not exist
if [ ! -f /data/Melbourne.osm ]; then
    echo "Downloading Melbourne.osm.gz...";
    curl -o /data/Melbourne.osm.gz "https://download.bbbike.org/osm/bbbike/Melbourne/Melbourne.osm.gz";
    echo "Extracting...";
    gzip -d /data/Melbourne.osm.gz;
    rm -f /data/Melbourne.osm.gz;
    echo "OSM file downloaded.";
else
    echo "Melbourne.osm already exists, skipping download.";
fi

# Wait for database
echo "Waiting for PostgreSQL database to be ready..."
until pg_isready -h db -p 5432 -U postgres; do
  sleep 2;
done

export PGPASSWORD=postgres

echo "PostgreSQL is ready. Starting data import..."

if psql -h db -U postgres -d nOPark -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='ways';" | grep -q 1; then
  row_count=$(psql -h db -U postgres -d nOPark -tAc "SELECT count(*) FROM ways;")
  if [ "$row_count" -gt 100 ]; then
    echo "OSM data already imported (ways > 100), skipping setup."
    exit 0
  fi
fi

if [ "$IMPORT_MODE" = "raw" ]; then
  echo "IMPORT_MODE=raw: Importing OSM data using osm2pgrouting..."
  osm2pgrouting --f /data/Melbourne.osm \
              --conf /osm/osm2pgrouting_custom.xml \
              --dbname nOPark \
              --username postgres \
              --host db \
              --port 5432 \
              --password postgres \
              --addnodes \
              --clean

  echo "pgRouting topology creation complete."
else
  echo "IMPORT_MODE is not 'raw': Importing OSM data using pre-processed SQL dump."
  if [ ! -f /data/nOPark.sql.gz ]; then
      echo "Pre-processed SQL dump not found, please upload nOPark.sql.gz to the ./data directory and restart the container";
  else
      echo "Extracting...";
      gzip -d /data/nOPark.sql.gz;
      psql -h db -U postgres -d nOPark -f /data/nOPark.sql;
      rm -f /data/nOPark.sql;
      echo "Pre-processed SQL import complete.";
  fi
fi

echo "Running postprocess_ways.sql..."
psql -h db -U postgres -d nOPark -f /osm/postprocess_ways.sql

echo "Running routing_functions.sql..."
psql -h db -U postgres -d nOPark -f /osm/routing_functions.sql

echo "Postprocessing and routing function setup complete."
echo "OSM data import and setup completed successfully."


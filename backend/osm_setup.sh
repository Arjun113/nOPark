#!/bin/bash

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

osm2pgrouting --f /data/Melbourne.osm \
            --conf /data/osm2pgrouting_custom.xml \
            --dbname nOPark \
            --username postgres \
            --host db \
            --port 5432 \
            --password postgres \
            --addnodes \
            --clean

echo "pgRouting topology creation complete."


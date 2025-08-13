#!/bin/bash

# Wait for the database to be ready
echo "Waiting for PostgreSQL database to be ready..."
until pg_isready -h db -p 5432 -U postgres; do
  sleep 2;
done

echo "PostgreSQL is ready. Starting data import with osm2pgsql..."

# Set password for PostgreSQL connection
export PGPASSWORD=postgres

# Use osm2pgsql to import the Melbourne PBF file
# --create will drop and recreate tables.
# --slim uses database for temporary storage, good for large imports.
# --hstore adds hstore column for all OSM tags.
# --host points to the 'db' service in the docker-compose network
osm2pgsql --create --slim --host db --port 5432 --database nOPark --user postgres --hstore --style /usr/share/osm2pgsql/default.style /data/melbourne-latest.osm.pbf

echo "Data import complete."

# Now create the routing topology with pgRouting
# The query below is a simple example to create a topology on the "planet_osm_line" table.
# This assumes the imported data has a "highway" column.
echo "Creating pgRouting topology..."
psql "postgresql://postgres:postgres@db:5432/nOPark" -c "
  ALTER TABLE planet_osm_line ADD COLUMN source INTEGER;
  ALTER TABLE planet_osm_line ADD COLUMN target INTEGER;
  SELECT pgr_createTopology('planet_osm_line', 0.00001, 'way', 'osm_id', clean := true);
"

echo "pgRouting topology created."
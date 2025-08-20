FROM postgres:17

# Install PostGIS and pgRouting dependencies
RUN apt-get update && apt-get install -y \
    postgresql-17-postgis-3 \
    postgresql-17-pgrouting \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables (these will be overridden by docker-compose)
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=nOPark

# Create initialization script to enable extensions
RUN echo "CREATE EXTENSION IF NOT EXISTS postgis;" > /docker-entrypoint-initdb.d/init.sql && \
    echo "CREATE EXTENSION IF NOT EXISTS pgrouting;" >> /docker-entrypoint-initdb.d/init.sql && \
    echo "CREATE EXTENSION IF NOT EXISTS hstore;" >> /docker-entrypoint-initdb.d/init.sql && \
    chown postgres:postgres /docker-entrypoint-initdb.d/init.sql

CMD ["/usr/local/bin/docker-entrypoint.sh","postgres"]

EXPOSE 5432
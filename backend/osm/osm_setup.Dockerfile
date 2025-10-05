FROM ubuntu:24.04

RUN apt-get update && apt-get install -y curl

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    g++ \
    git \
    libboost-dev \
    libboost-program-options-dev \
    libpqxx-dev \
    libexpat1-dev \
    expat \
    osmctools \
    wget \
    postgresql-client \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Download osm2pgrouting and build
RUN git clone https://github.com/pgRouting/osm2pgrouting.git /osm2pgrouting \
    && mkdir /osm2pgrouting/build \
    && cd /osm2pgrouting/build \
    && cmake -H.. -B. \
    && make \
    && make install

ENTRYPOINT ["/osm/osm_setup.sh"]






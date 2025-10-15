-- Table Definition ----------------------------------------------

CREATE TABLE rides (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR(50) NOT NULL DEFAULT 'awaiting_confirmation' CHECK (status IN ('awaiting_confirmation', 'in_progress', 'completed', 'rejected')),
    destination_latitude DECIMAL(9,6) NOT NULL CHECK (destination_latitude IS NULL OR destination_latitude BETWEEN -90 AND 90),
    destination_longitude DECIMAL(9,6) NOT NULL CHECK (destination_longitude IS NULL OR destination_longitude BETWEEN -180 AND 180),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE requests (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pickup_location VARCHAR(100),
    pickup_latitude DECIMAL(9,6) NOT NULL CHECK (pickup_latitude BETWEEN -90 AND 90),
    pickup_longitude DECIMAL(9,6) NOT NULL CHECK (pickup_longitude BETWEEN -180 AND 180),
    dropoff_location VARCHAR(100) NOT NULL,
    dropoff_latitude DECIMAL(9,6) NOT NULL CHECK (dropoff_latitude BETWEEN -90 AND 90),
    dropoff_longitude DECIMAL(9,6) NOT NULL CHECK (dropoff_longitude BETWEEN -180 AND 180),
    compensation DECIMAL(10, 2) NOT NULL,
    passenger_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    ride_id BIGINT REFERENCES rides(id) ON DELETE CASCADE,
    notifs_crtd BOOLEAN NOT NULL DEFAULT FALSE,
    visited BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE proposals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    driver_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    ride_id BIGINT NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (request_id, ride_id)
);

-- Indices -------------------------------------------------------

-- Triggers ------------------------------------------------------

CREATE TRIGGER on_proposals_update_set_updated_columns
BEFORE UPDATE ON proposals
FOR EACH ROW
EXECUTE PROCEDURE set_updated_columns();

CREATE TRIGGER on_rides_update_set_updated_columns
BEFORE UPDATE ON rides
FOR EACH ROW
EXECUTE PROCEDURE set_updated_columns();

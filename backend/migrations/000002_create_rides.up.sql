-- Table Definition ----------------------------------------------

CREATE TABLE requests (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pickup_location VARCHAR(255) NOT NULL,
    dropoff_location VARCHAR(255) NOT NULL,
    compensation DECIMAL(10, 2) NOT NULL,
    passenger_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    ride_id BIGINT NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
)

CREATE TABLE proposals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    driver_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    ride_id BIGINT REFERENCES rides(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE rides (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR(50) NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
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

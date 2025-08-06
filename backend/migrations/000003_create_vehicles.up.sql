-- Table Definition ----------------------------------------------

CREATE TABLE vehicles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    model_year INT NOT NULL,
    colour VARCHAR(30) NOT NULL,
    license_plate VARCHAR(20) NOT NULL UNIQUE,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indices -------------------------------------------------------

-- Triggers ------------------------------------------------------

CREATE TRIGGER on_vehicles_update_set_updated_columns
BEFORE UPDATE ON vehicles
FOR EACH ROW
EXECUTE PROCEDURE set_updated_columns();

-- Table Definition ----------------------------------------------

CREATE TABLE licenses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    license_no VARCHAR(50) NOT NULL UNIQUE,
    date_of_issue DATE NOT NULL,
    expiry DATE NOT NULL,
    card_number VARCHAR(50) NOT NULL UNIQUE,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indices -------------------------------------------------------

-- Triggers ------------------------------------------------------

CREATE TRIGGER on_licenses_update_set_updated_columns
BEFORE UPDATE ON licenses
FOR EACH ROW
EXECUTE PROCEDURE set_updated_columns();

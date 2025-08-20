-- Table Definition ----------------------------------------------
CREATE TABLE accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type VARCHAR(50) NOT NULL CHECK (type IN ('admin', 'passenger', 'driver')),
    email VARCHAR(200) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    firstname VARCHAR(50) NOT NULL,
    middlename VARCHAR(50),
    lastname VARCHAR(50) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE NOT NULL,
    email_verification_token TEXT,
    email_verification_expires_at TIMESTAMP WITH TIME ZONE,
    password_reset_token TEXT,
    password_reset_expires_at TIMESTAMP WITH TIME ZONE,
    current_latitude DECIMAL(9, 6) CHECK (current_latitude BETWEEN -90 AND 90),
    current_longitude DECIMAL(9, 6) CHECK (current_longitude BETWEEN -180 AND 180),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE account_addresses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    address_line VARCHAR(100) NOT NULL,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE sessions (
    id TEXT NOT NULL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    secret_hash BYTEA NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indices -------------------------------------------------------

-- Triggers ------------------------------------------------------

-- Something like this needs to be added for each new table
CREATE TRIGGER on_accounts_update_set_updated_columns
BEFORE UPDATE ON accounts
FOR EACH ROW
EXECUTE PROCEDURE set_updated_columns();

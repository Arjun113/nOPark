-- Table Definition ----------------------------------------------
CREATE TABLE accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(200) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    firstname VARCHAR(50) NOT NULL,
    middlename VARCHAR(50),
    lastname VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
);

CREATE TABLE sessions (
    id TEXT NOT NULL PRIMARY KEY,
    secret_hash BYTEA NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
);

-- Indices -------------------------------------------------------

-- Triggers ------------------------------------------------------

-- Something like this needs to be added for each new table
CREATE TRIGGER on_accounts_update_set_updated_columns
BEFORE UPDATE ON accounts
FOR EACH ROW
EXECUTE PROCEDURE set_updated_columns();

-- Table Definition ----------------------------------------------

CREATE TABLE notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN ('review', 'proximity', 'ride_status')),
    notification_message VARCHAR(100) NOT NULL,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indices -------------------------------------------------------

-- Triggers ------------------------------------------------------

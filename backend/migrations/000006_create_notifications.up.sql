-- Table Definition ----------------------------------------------

CREATE TABLE notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN ('review', 'proximity', 'ride_updates')),
    notification_message VARCHAR(100) NOT NULL,
    payload VARCHAR(255),
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    is_sent BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indices -------------------------------------------------------

CREATE INDEX idx_notifications_sent_created ON notifications(is_sent, created_at) WHERE is_sent = FALSE;

-- Triggers ------------------------------------------------------

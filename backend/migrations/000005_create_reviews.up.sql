-- Table Definition ----------------------------------------------

CREATE TABLE reviews (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stars INT NOT NULL CHECK (stars >= 1 AND stars <= 5),
    comment VARCHAR(250) NOT NULL,
    reviewer_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    reviewee_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
);

-- Indices -------------------------------------------------------

-- Triggers ------------------------------------------------------

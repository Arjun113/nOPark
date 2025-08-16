-- Table Definition ----------------------------------------------
    
-- Indices -------------------------------------------------------



-- Triggers ------------------------------------------------------



-- Table Changes ------------------------------------------------

-- Merge into 000002_create_rides.up.sql eventually.

-- Update additional statuses for rides
ALTER TABLE rides ALTER COLUMN status SET DEFAULT 'awaiting_confirmation';
ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_status_check;
ALTER TABLE rides ADD CONSTRAINT rides_status_check CHECK (status IN ('awaiting_confirmation','in_progress', 'completed','rejected'));

UPDATE rides SET status = 'awaiting_confirmation' WHERE status = 'in_progress';

ALTER TABLE proposals ALTER COLUMN ride_id DROP NOT NULL;

-- Add unique constraint on proposals (request_id, driver_id)
ALTER TABLE proposals ADD CONSTRAINT unique_proposal UNIQUE (request_id, ride_id);
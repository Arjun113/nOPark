-- Table Definition ----------------------------------------------
    
-- Indices -------------------------------------------------------



-- Triggers ------------------------------------------------------



-- Table Changes ------------------------------------------------

ALTER TABLE rides ALTER COLUMN status SET DEFAULT 'awaiting_confirmation';
ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_status_check;
ALTER TABLE rides ADD CONSTRAINT rides_status_check CHECK (status IN ('awaiting_confirmation','in_progress', 'completed'));

UPDATE rides SET status = 'awaiting_confirmation' WHERE status = 'in_progress';
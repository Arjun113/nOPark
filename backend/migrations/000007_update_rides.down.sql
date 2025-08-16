ALTER TABLE rides ALTER COLUMN status SET DEFAULT 'in_progress';
ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_status_check;
ALTER TABLE rides ADD CONSTRAINT rides_status_check CHECK (status IN ('in_progress', 'completed'));
UPDATE rides SET status = 'in_progress' WHERE status = 'awaiting_confirmation';

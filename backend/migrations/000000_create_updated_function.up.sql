-- Functions -----------------------------------------------------

-- This can be used across multiple tables to set the updated_at column
CREATE OR REPLACE FUNCTION set_updated_columns()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
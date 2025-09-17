-- Revert to original imported structure
UPDATE ways
SET cost = "length",
    reverse_cost = "length";

UPDATE ways
SET reverse_cost = -1 * "length"
WHERE upper(oneway) = 'YES';

UPDATE ways
SET cost = -1 * "length"
WHERE upper(oneway) = 'REVERSED';

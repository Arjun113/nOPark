-- Initialize cost and reverse_cost as bidirectional by default
UPDATE ways
SET cost = length_m,
    reverse_cost = length_m;

-- forward only
UPDATE ways
SET cost = length_m,
    reverse_cost = 1000000000
WHERE upper(oneway) = 'YES';

-- reverse only
UPDATE ways
SET cost = 1000000000,
    reverse_cost = length_m
WHERE upper(oneway) = 'REVERSED';

-- bidirectional
UPDATE ways
SET cost = length_m,
    reverse_cost = length_m
WHERE upper(oneway) = 'NO';

-- unknown: treat as bidirectional
UPDATE ways
SET cost = length_m,
    reverse_cost = length_m
WHERE upper(oneway) = 'UNKNOWN';

-- make NULL costs impassable
UPDATE ways
SET cost = 1000000000
WHERE cost IS NULL;

UPDATE ways
SET reverse_cost = 1000000000
WHERE reverse_cost IS NULL;
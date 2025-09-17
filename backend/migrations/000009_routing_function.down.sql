-- Drop the get_route_between function if it exists
DROP FUNCTION IF EXISTS get_route_between(
    double precision,
    double precision,
    double precision,
    double precision
);
-- Routing function using pgRouting with distance and time (fully qualified, no ambiguity)
CREATE OR REPLACE FUNCTION get_route_between(
    start_lon double precision,
    start_lat double precision,
    end_lon double precision,
    end_lat double precision
)
RETURNS TABLE(
    seq integer,
    node bigint,
    edge bigint,
    cost double precision,
    cost_s double precision,
    agg_cost double precision,
    agg_cost_s double precision,
    geom text
) AS $$
DECLARE
    start_edge record;
    end_edge record;
    start_proj geometry;
    end_proj geometry;
    start_node bigint;
    end_node bigint;
    start_point geometry := ST_SetSRID(ST_MakePoint(start_lon, start_lat), 4326);
    end_point geometry := ST_SetSRID(ST_MakePoint(end_lon, end_lat), 4326);
    dijkstra_count integer;
BEGIN
    -- nearest edge to start
    SELECT w.gid, w.source, w.target, w.the_geom, w.cost AS w_cost, w.cost_s AS w_cost_s
    INTO start_edge
    FROM ways w
    ORDER BY w.the_geom <-> start_point
    LIMIT 1;

    start_proj := ST_ClosestPoint(start_edge.the_geom, start_point);

    SELECT CASE
        WHEN ST_Distance(start_proj, (SELECT v.the_geom FROM ways_vertices_pgr v WHERE v.id=start_edge.source)) <
             ST_Distance(start_proj, (SELECT v.the_geom FROM ways_vertices_pgr v WHERE v.id=start_edge.target))
        THEN start_edge.source
        ELSE start_edge.target
    END INTO start_node;

    -- nearest edge to end
    SELECT w.gid, w.source, w.target, w.the_geom, w.cost AS w_cost, w.cost_s AS w_cost_s
    INTO end_edge
    FROM ways w
    ORDER BY w.the_geom <-> end_point
    LIMIT 1;

    end_proj := ST_ClosestPoint(end_edge.the_geom, end_point);

    SELECT CASE
        WHEN ST_Distance(end_proj, (SELECT v.the_geom FROM ways_vertices_pgr v WHERE v.id=end_edge.source)) <
             ST_Distance(end_proj, (SELECT v.the_geom FROM ways_vertices_pgr v WHERE v.id=end_edge.target))
        THEN end_edge.source
        ELSE end_edge.target
    END INTO end_node;

    -- count Dijkstra edges
    SELECT COUNT(*) INTO dijkstra_count
    FROM pgr_dijkstra(
        'SELECT gid AS id, source, target, cost, reverse_cost FROM ways',
        start_node, end_node, true
    );

    -- build and return full route table at once
    RETURN QUERY
    WITH start_hops AS (
        SELECT 1 AS s_seq,
               NULL::bigint AS s_node,
               start_edge.gid AS s_edge,
               ST_Distance(start_point, start_proj) AS s_cost,
               (ST_Distance(start_point, start_proj)/NULLIF(start_edge.w_cost,0)) * start_edge.w_cost_s AS s_cost_s,
               ST_MakeLine(start_point, start_proj) AS s_geom
        UNION ALL
        SELECT 2 AS s_seq,
               start_node AS s_node,
               start_edge.gid AS s_edge,
               ST_Distance(start_proj, v.the_geom) AS s_cost,
               (ST_Distance(start_proj, v.the_geom)/NULLIF(start_edge.w_cost,0)) * start_edge.w_cost_s AS s_cost_s,
               ST_MakeLine(start_proj, v.the_geom) AS s_geom
        FROM ways_vertices_pgr v
        WHERE v.id = start_node
    ),
    main_route AS (
        SELECT (r.seq + 2) AS m_seq,
               r.node AS m_node,
               r.edge AS m_edge,
               w.cost AS m_cost,
               w.cost_s AS m_cost_s,
               w.the_geom AS m_geom
        FROM pgr_dijkstra(
            'SELECT gid AS id, source, target, cost, reverse_cost FROM ways',
            start_node, end_node, true
        ) AS r
        JOIN ways w ON r.edge = w.gid
    ),
    end_hops AS (
        SELECT (dijkstra_count + 3) AS e_seq,
               end_node AS e_node,
               end_edge.gid AS e_edge,
               ST_Distance(v.the_geom, end_proj) AS e_cost,
               (ST_Distance(v.the_geom, end_proj)/NULLIF(end_edge.w_cost,0)) * end_edge.w_cost_s AS e_cost_s,
               ST_MakeLine(v.the_geom, end_proj) AS e_geom
        FROM ways_vertices_pgr v
        WHERE v.id = end_node
        UNION ALL
        SELECT (dijkstra_count + 4) AS e_seq,
               NULL::bigint AS e_node,
               end_edge.gid AS e_edge,
               ST_Distance(end_proj, end_point) AS e_cost,
               (ST_Distance(end_proj, end_point)/NULLIF(end_edge.w_cost,0)) * end_edge.w_cost_s AS e_cost_s,
               ST_MakeLine(end_proj, end_point) AS e_geom
    ),
    all_segments AS (
        SELECT s_seq AS seq, s_node AS node, s_edge AS edge, s_cost AS cost, s_cost_s AS cost_s, s_geom AS geom
        FROM start_hops
        UNION ALL
        SELECT m_seq, m_node, m_edge, m_cost, m_cost_s, m_geom
        FROM main_route
        UNION ALL
        SELECT e_seq, e_node, e_edge, e_cost, e_cost_s, e_geom
        FROM end_hops
    )
    SELECT
        all_segments.seq,
        all_segments.node,
        all_segments.edge,
        all_segments.cost,
        all_segments.cost_s,
        SUM(all_segments.cost) OVER (ORDER BY all_segments.seq) AS agg_cost,
        SUM(all_segments.cost_s) OVER (ORDER BY all_segments.seq) AS agg_cost_s,
        ST_AsGeoJSON(all_segments.geom) AS geom
    FROM all_segments
    ORDER BY all_segments.seq;

END;
$$ LANGUAGE plpgsql STABLE;


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
    WITH
    -- start_hops: off-road then road-following
    start_hops AS (
        SELECT
            1 AS sh_seq,
            NULL::bigint AS sh_node,
            start_edge.gid AS sh_edge,
            ST_Distance(start_point, start_proj) AS sh_cost,
            (ST_Distance(start_point, start_proj) / NULLIF(start_edge.w_cost, 0)) * start_edge.w_cost_s AS sh_cost_s,
            ST_MakeLine(start_point, start_proj) AS sh_geom
        UNION ALL
        SELECT
            2 AS sh_seq,
            start_node AS sh_node,
            start_edge.gid AS sh_edge,
            ST_Length(
                ST_LineSubstring(
                    start_edge.the_geom,
                    LEAST(ST_LineLocatePoint(start_edge.the_geom, start_proj),
                        ST_LineLocatePoint(start_edge.the_geom, v.the_geom)),
                    GREATEST(ST_LineLocatePoint(start_edge.the_geom, start_proj),
                            ST_LineLocatePoint(start_edge.the_geom, v.the_geom))
                )::geography
            ) AS sh_cost,
            (
                ST_Length(
                    ST_LineSubstring(
                        start_edge.the_geom,
                        LEAST(ST_LineLocatePoint(start_edge.the_geom, start_proj),
                            ST_LineLocatePoint(start_edge.the_geom, v.the_geom)),
                        GREATEST(ST_LineLocatePoint(start_edge.the_geom, start_proj),
                                ST_LineLocatePoint(start_edge.the_geom, v.the_geom))
                    )::geography
                ) / NULLIF(start_edge.w_cost, 0)
            ) * start_edge.w_cost_s AS sh_cost_s,
            ST_LineSubstring(
                start_edge.the_geom,
                LEAST(ST_LineLocatePoint(start_edge.the_geom, start_proj),
                    ST_LineLocatePoint(start_edge.the_geom, v.the_geom)),
                GREATEST(ST_LineLocatePoint(start_edge.the_geom, start_proj),
                        ST_LineLocatePoint(start_edge.the_geom, v.the_geom))
            ) AS sh_geom
        FROM ways_vertices_pgr v
        WHERE v.id = start_node
    ),

    -- main_route
    main_route AS (
        SELECT
            r.seq + 2 AS mr_seq,
            r.node AS mr_node,
            r.edge AS mr_edge,
            w.cost AS mr_cost,
            w.cost_s AS mr_cost_s,
            w.the_geom AS mr_geom
        FROM pgr_dijkstra(
            'SELECT gid AS id, source, target, cost, reverse_cost FROM ways',
            start_node, end_node, true
        ) AS r
        JOIN ways w ON r.edge = w.gid
    ),

    -- end_hops
    end_hops AS (
        SELECT
            dijkstra_count + 2 AS eh_seq,
            end_node AS eh_node,
            end_edge.gid AS eh_edge,
            ST_Length(
                ST_LineSubstring(
                    end_edge.the_geom,
                    LEAST(ST_LineLocatePoint(end_edge.the_geom, v.the_geom),
                        ST_LineLocatePoint(end_edge.the_geom, end_proj)),
                    GREATEST(ST_LineLocatePoint(end_edge.the_geom, v.the_geom),
                            ST_LineLocatePoint(end_edge.the_geom, end_proj))
                )::geography
            ) AS eh_cost,
            (
                ST_Length(
                    ST_LineSubstring(
                        end_edge.the_geom,
                        LEAST(ST_LineLocatePoint(end_edge.the_geom, v.the_geom),
                            ST_LineLocatePoint(end_edge.the_geom, end_proj)),
                        GREATEST(ST_LineLocatePoint(end_edge.the_geom, v.the_geom),
                                ST_LineLocatePoint(end_edge.the_geom, end_proj))
                    )::geography
                ) / NULLIF(end_edge.w_cost, 0)
            ) * end_edge.w_cost_s AS eh_cost_s,
            ST_LineSubstring(
                end_edge.the_geom,
                LEAST(ST_LineLocatePoint(end_edge.the_geom, v.the_geom),
                    ST_LineLocatePoint(end_edge.the_geom, end_proj)),
                GREATEST(ST_LineLocatePoint(end_edge.the_geom, v.the_geom),
                        ST_LineLocatePoint(end_edge.the_geom, end_proj))
            ) AS eh_geom
        FROM ways_vertices_pgr v
        WHERE v.id = end_node
        UNION ALL
        SELECT
            dijkstra_count + 3 AS eh_seq,
            NULL::bigint AS eh_node,
            end_edge.gid AS eh_edge,
            ST_Distance(end_proj, end_point) AS eh_cost,
            (ST_Distance(end_proj, end_point) / NULLIF(end_edge.w_cost, 0)) * end_edge.w_cost_s AS eh_cost_s,
            ST_MakeLine(end_proj, end_point) AS eh_geom
    ),

    -- unify all pieces
    all_segments AS (
        SELECT sh_seq AS seq, sh_node AS node, sh_edge AS edge, sh_cost AS cost, sh_cost_s AS cost_s, sh_geom AS geom FROM start_hops
        UNION ALL
        SELECT mr_seq AS seq, mr_node AS node, mr_edge AS edge, mr_cost AS cost, mr_cost_s AS cost_s, mr_geom AS geom FROM main_route
        UNION ALL
        SELECT eh_seq AS seq, eh_node AS node, eh_edge AS edge, eh_cost AS cost, eh_cost_s AS cost_s, eh_geom AS geom FROM end_hops
    )

    -- final output
    SELECT
        all_segments.seq,
        all_segments.node,
        all_segments.edge,
        all_segments.cost,
        all_segments.cost_s,
        SUM(all_segments.cost) OVER (ORDER BY all_segments.seq) AS agg_cost,
        SUM(all_segments.cost_s) OVER (ORDER BY all_segments.seq) AS agg_cost_s,
        ST_AsGeoJSON(all_segments.geom)::text AS geom
    FROM all_segments
    ORDER BY all_segments.seq;
END;
$$ LANGUAGE plpgsql STABLE;
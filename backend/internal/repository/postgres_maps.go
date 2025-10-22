package repository

import (
	"context"

	"github.com/Arjun113/nOPark/internal/domain"
)

type postgresMapsRepository struct {
	conn Connection
}

func NewPostgresMaps(conn Connection) domain.MapsRepository {
	return &postgresMapsRepository{conn: conn}
}

func (p *postgresMapsRepository) GetDirectRoute(ctx context.Context, start domain.Coordinates, dest domain.Coordinates) (*domain.RouteDBModel, error) {
	rows, err := p.conn.Query(ctx, `SELECT * FROM get_route_between($1, $2, $3, $4)`, start.Lon, start.Lat, dest.Lon, dest.Lat)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var coordinates [][]float64
	var totalDistance float64
	var estimatedDuration float64

	for rows.Next() {
		var seq int
		var node, edge *int64
		var cost, costS, aggCost, aggCostS float64
		var geomText string
		if err := rows.Scan(&seq, &node, &edge, &cost, &costS, &aggCost, &aggCostS, &geomText); err != nil {
			return nil, err
		}

		// Parse GeoJSON string to extract coordinates
		lineString := domain.ExtractCoordinatesFromGeoJSON(geomText)
		if len(lineString) <= 0 {
			continue
		}

		// Latest tracking
		dest.Lon = lineString[len(lineString)-1][0]
		dest.Lat = lineString[len(lineString)-1][1]
		totalDistance = aggCost
		estimatedDuration = aggCostS

		// Coordinates list construction
		if len(coordinates) == 0 {
			// First segment, just add all
			coordinates = append(coordinates, lineString...)
		} else {
			// Continuing segments
			prevCoords := &coordinates[len(coordinates)-1]
			leftCoords := &lineString[0]
			if (*prevCoords)[0] == (*leftCoords)[0] && (*prevCoords)[1] == (*leftCoords)[1] {
				// Insert left to right, skipping first
				coordinates = append(coordinates, lineString[1:]...)
			} else {
				rightCoords := &lineString[len(lineString)-1]
				if (*prevCoords)[0] == (*rightCoords)[0] && (*prevCoords)[1] == (*rightCoords)[1] {
					// Insert right to left, skipping last
					for i := len(lineString) - 2; i >= 0; i-- {
						coordinates = append(coordinates, lineString[i])
					}
				}
			}
		}

	}

	polyline := domain.EncodePolyline(coordinates)

	route := domain.RouteDBModel{
		StartLatitude:  start.Lat,
		StartLongitude: start.Lon,
		EndLatitude:    dest.Lat,
		EndLongitude:   dest.Lon,
		Distance:       totalDistance,
		Duration:       int64(estimatedDuration),
		Polyline:       polyline,
	}

	return &route, nil
}

func (p *postgresMapsRepository) GetMultistopRoute(ctx context.Context, start domain.Coordinates, waypoints []domain.Coordinates, dest domain.Coordinates) (*domain.RouteDBModel, error) {
	// Traverses waypoints in-order
	if len(waypoints) == 0 {
		return p.GetDirectRoute(ctx, start, dest)
	}

	var polylines []string
	var totalDistance float64
	var totalDuration int64

	stops := []domain.Coordinates{start}
	stops = append(stops, waypoints...)
	stops = append(stops, dest)

	legCount := len(stops) - 1
	for i := range legCount {
		legRoute, err := p.GetDirectRoute(ctx, stops[i], stops[i+1])
		if err != nil {
			return nil, err
		}
		polylines = append(polylines, legRoute.Polyline)

		totalDistance += legRoute.Distance
		totalDuration += legRoute.Duration
	}

	combinedPolyline, err := domain.CombinePolylines(polylines)
	if err != nil {
		return nil, err
	}

	return &domain.RouteDBModel{
		StartLatitude:  start.Lat,
		StartLongitude: start.Lon,
		EndLatitude:    dest.Lat,
		EndLongitude:   dest.Lon,
		Distance:       totalDistance,
		Duration:       totalDuration,
		Polyline:       combinedPolyline,
	}, nil
}

func (p *postgresMapsRepository) GetRouteFromWaypoints(ctx context.Context, start domain.Coordinates, waypoints []domain.Coordinates, dest domain.Coordinates) (*domain.RouteDBModel, error) {
	// waypoints are in any-order
	var bestRoute *domain.RouteDBModel

	if len(waypoints) == 0 {
		return p.GetDirectRoute(ctx, start, dest)
	}

	// Exhaustive search
	for _, waypointOrder := range permutations(waypoints) {
		route, err := p.GetMultistopRoute(ctx, start, waypointOrder, dest)
		if err != nil {
			return nil, err
		}
		// For simplicity, return the first found route

		if bestRoute == nil || route.Distance < bestRoute.Distance {
			bestRoute = route
		}
	}
	return bestRoute, nil
}

func permutations(coords []domain.Coordinates) [][]domain.Coordinates {
	var res [][]domain.Coordinates
	var generate func([]domain.Coordinates, int)
	generate = func(a []domain.Coordinates, n int) {
		if n == 1 {
			perm := make([]domain.Coordinates, len(a))
			copy(perm, a)
			res = append(res, perm)
			return
		}
		for i := 0; i < n; i++ {
			generate(a, n-1)
			if n%2 == 1 {
				a[0], a[n-1] = a[n-1], a[0]
			} else {
				a[i], a[n-1] = a[n-1], a[i]
			}
		}
	}
	generate(coords, len(coords))
	return res
}

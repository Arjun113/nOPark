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

func (p *postgresMapsRepository) GetRouteBetween(ctx context.Context, startLat float64, startLng float64, endLat float64, endLng float64) (*domain.RouteDBModel, error) {
	rows, err := p.conn.Query(ctx, `SELECT * FROM get_route_between($1, $2, $3, $4)`, startLng, startLat, endLng, endLat)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var coordinates [][]float64
	var totalDistance float64
	var estimatedDuration float64
	var startLatSet bool = false

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

		if !startLatSet {
			// First coordinate is start
			startLng = lineString[0][0]
			startLat = lineString[0][1]
			startLatSet = true
		}

		// Latest tracking
		endLng = lineString[len(lineString)-1][0]
		endLat = lineString[len(lineString)-1][1]
		totalDistance = aggCost
		estimatedDuration = aggCostS

		// Coordinates update
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
		StartLatitude:  startLat,
		StartLongitude: startLng,
		EndLatitude:    endLat,
		EndLongitude:   endLng,
		Distance:       totalDistance,
		Duration:       int(estimatedDuration),
		Polyline:       polyline,
	}

	return &route, nil
}

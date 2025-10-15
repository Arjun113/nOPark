package domain

import (
	"context"
	"encoding/json"
	"math"
	"strings"
)

type geoJSONLineString struct {
	Type        string      `json:"type"`
	Coordinates [][]float64 `json:"coordinates"`
}

type RouteDBModel struct {
	StartLatitude  float64
	StartLongitude float64
	EndLatitude    float64
	EndLongitude   float64
	Distance       float64
	Duration       int64
	Polyline       string
}

type Coordinates struct {
	Lat, Lon float64
}

type MapsRepository interface {
	GetDirectRoute(ctx context.Context, start Coordinates, dest Coordinates) (*RouteDBModel, error)
	GetMultistopRoute(ctx context.Context, start Coordinates, waypoints []Coordinates, dest Coordinates) (*RouteDBModel, error)
	GetRouteFromWaypoints(ctx context.Context, start Coordinates, waypoints []Coordinates, dest Coordinates) (*RouteDBModel, error)
}

// ExtractCoordinatesFromGeoJSON parses a GeoJSON LineString and returns [][]float64
func ExtractCoordinatesFromGeoJSON(geojson string) [][]float64 {
	var line geoJSONLineString
	if err := json.Unmarshal([]byte(geojson), &line); err != nil {
		return nil
	}
	return line.Coordinates
}

// EncodePolyline encodes coordinates to polyline format
func EncodePolyline(coordinates [][]float64) string {
	if len(coordinates) == 0 {
		return ""
	}

	var encoded strings.Builder
	var prevLat, prevLng int = 0, 0

	for _, coord := range coordinates {
		// coord[0] = longitude, coord[1] = latitude
		lat := int(math.Round(coord[1] * 1e5))
		lng := int(math.Round(coord[0] * 1e5))

		// Calculate deltas
		deltaLat := lat - prevLat
		deltaLng := lng - prevLng

		// Encode deltas
		encoded.WriteString(encodeValue(deltaLat))
		encoded.WriteString(encodeValue(deltaLng))

		prevLat = lat
		prevLng = lng
	}

	return encoded.String()
}

// encodeValue encodes a single integer value for polyline
func encodeValue(value int) string {
	// Handle negative numbers using correct polyline algorithm
	if value < 0 {
		value = (^value << 1) | 1 // Invert value, shift left, set least significant bit
	} else {
		value = value << 1
	}

	var encoded strings.Builder

	// Split into 5-bit chunks
	for value >= 0x20 {
		encoded.WriteByte(byte((value&0x1f)|0x20) + 63)
		value >>= 5
	}
	encoded.WriteByte(byte(value) + 63)

	return encoded.String()
}

func DecodePolyline(encoded string) [][]float64 {
	var coords [][]float64
	index := 0
	lat, lon := 0, 0

	for index < len(encoded) {
		// Decode latitude
		result, shift := 0, 0
		for {
			b := int(encoded[index]) - 63
			index++
			result |= (b & 0x1F) << shift
			shift += 5
			if b < 0x20 {
				break
			}
		}
		dlat := (result >> 1) ^ (-(result & 1))
		lat += dlat

		// Decode longitude
		result, shift = 0, 0
		for {
			b := int(encoded[index]) - 63
			index++
			result |= (b & 0x1F) << shift
			shift += 5
			if b < 0x20 {
				break
			}
		}
		dlon := (result >> 1) ^ (-(result & 1))
		lon += dlon

		coords = append(coords, []float64{float64(lon) * 1e-5, float64(lat) * 1e-5}) // [lon, lat] for WKT
	}

	return coords
}

func CombinePolylines(polys []string) (string, error) {
	if len(polys) == 0 {
		return "", nil
	}

	var combinedCoords [][]float64

	for i, p := range polys {
		coords := DecodePolyline(p)

		if i > 0 && len(coords) > 0 {
			// skip first point to avoid duplicate at junction
			coords = coords[1:]
		}

		combinedCoords = append(combinedCoords, coords...)
	}

	encoded := EncodePolyline(combinedCoords)
	return string(encoded), nil
}

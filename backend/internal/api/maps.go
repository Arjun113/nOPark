package api

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/Arjun113/nOPark/internal/domain"
)

type GetRouteRequest struct {
	StartLat float64 `json:"start_lat" validate:"required,min=-90,max=90"`
	StartLng float64 `json:"start_lng" validate:"required,min=-180,max=180"`
	EndLat   float64 `json:"end_lat" validate:"required,min=-90,max=90"`
	EndLng   float64 `json:"end_lng" validate:"required,min=-180,max=180"`
}

type GetRouteResponse struct {
	StartLat float64 `json:"start_lat"`
	StartLng float64 `json:"start_lng"`
	EndLat   float64 `json:"end_lat"`
	EndLng   float64 `json:"end_lng"`
	Distance float64 `json:"distance"`
	Duration int64   `json:"duration"`
	Polyline string  `json:"polyline"`
}

func (a *api) getRouteHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	var req GetRouteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	route, err := a.mapsRepo.GetDirectRoute(ctx,
		domain.Coordinates{Lat: req.StartLat, Lon: req.StartLng},
		domain.Coordinates{Lat: req.EndLat, Lon: req.EndLng},
	)

	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := GetRouteResponse{
		StartLat: route.StartLatitude,
		StartLng: route.StartLongitude,
		EndLat:   route.EndLatitude,
		EndLng:   route.EndLongitude,
		Distance: route.Distance,
		Duration: route.Duration,
		Polyline: route.Polyline,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/Arjun113/nOPark/internal/utils"
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

type GetRouteForRideRequest struct {
	RideID int64 `json:"ride_id" validate:"required"`
}

func (a *api) getRouteForRideHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	rideID, err := utils.IntFromQueryParam(r, "ride_id", false)
	if err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	reqParams := GetRouteForRideRequest{
		RideID: *rideID,
	}
	if err := a.validateRequest(reqParams); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	ride, proposals, err := a.ridesRepo.GetRideAndProposals(ctx, reqParams.RideID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if ride.Status != "in_progress" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("ride is not in progress"))
		return
	}

	driver, err := a.accountsRepo.GetAccountByID(ctx, proposals[0].DriverID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Collect waypoints from proposals and determine destination
	waypoints := make([]domain.Coordinates, 0)

	// Use ride's destination coordinates if available, otherwise get from request
	destination := domain.Coordinates{
		Lat: ride.DestinationLatitude,
		Lon: ride.DestinationLongitude,
	}

	// Process all accepted proposals to collect waypoints
	for _, prop := range proposals {
		if prop.Status == "accepted" {
			request, err := a.ridesRepo.GetRequestByID(ctx, prop.RequestID)
			if err != nil {
				a.errorResponse(w, r, http.StatusInternalServerError, err)
				return
			}
			if request.Visited {
				continue
			}

			waypoints = append(waypoints, domain.Coordinates{Lat: request.PickupLatitude, Lon: request.PickupLongitude})
		}
	}

	route, err := a.mapsRepo.GetRouteFromWaypoints(ctx,
		domain.Coordinates{Lat: *driver.CurrentLatitude, Lon: *driver.CurrentLongitude},
		waypoints,
		destination,
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

package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/Arjun113/nOPark/internal/domain"
)

type CreateRideRequestRequest struct {
	PickupLocation  string  `json:"pickup_location" validate:"required"`
	DropoffLocation string  `json:"dropoff_location" validate:"required"`
	Compensation    float64 `json:"compensation" validate:"required,gt=0"`
}

type CreateRideRequestResponse struct {
	ID              int64   `json:"id"`
	PickupLocation  string  `json:"pickup_location"`
	DropoffLocation string  `json:"dropoff_location"`
	Compensation    float64 `json:"compensation"`
	PassengerID     int64   `json:"passenger_id"`
	CreatedAt       string  `json:"created_at"`
}

func (a *api) createRideRequestHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	var req CreateRideRequestRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	account, err := a.getUserFromAuthHeader(r)
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}

	request := &domain.RequestDBModel{
		PickupLocation:  req.PickupLocation,
		DropoffLocation: req.DropoffLocation,
		Compensation:    req.Compensation,
		PassengerID:     account.ID,
	}

	createdRequest, err := a.ridesRepo.CreateRequest(ctx, request)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := CreateRideRequestResponse{
		ID:              createdRequest.ID,
		PickupLocation:  createdRequest.PickupLocation,
		DropoffLocation: createdRequest.DropoffLocation,
		Compensation:    createdRequest.Compensation,
		PassengerID:     createdRequest.PassengerID,
		CreatedAt:       createdRequest.CreatedAt,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}
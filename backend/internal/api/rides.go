package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

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

	account, err := a.accountsRepo.GetAccountFromSession(r.Context())
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}
	if account.Type != "passenger" {
		a.errorResponse(w, r, http.StatusForbidden, fmt.Errorf("only passengers can create ride requests"))
		return
	}

	request := &domain.RequestDBModel{
		PickupLocation:  req.PickupLocation,
		DropoffLocation: req.DropoffLocation,
		Compensation:    req.Compensation,
		PassengerID:     account.ID,
	}

	createdRequest, err := a.ridesRepo.CreateRideRequest(ctx, request)
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

type GetRideRequestsRequest struct {
	IDs          *[]string `json:"ids,omitempty"`
	Compensation *float64  `json:"compensation,omitempty"`
}

type GetRideRequestsResponseIndividual struct {
	ID              int64   `json:"id"`
	PickupLocation  string  `json:"pickup_location"`
	DropoffLocation string  `json:"dropoff_location"`
	Compensation    float64 `json:"compensation"`
	CreatedAt       string  `json:"created_at"`
}

type GetRideRequestsResponse struct {
	Requests []GetRideRequestsResponseIndividual `json:"requests"`
}

func (a *api) getRideRequestsHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	var ub_compensation *float64 = nil
	if compStr := r.URL.Query().Get("compensation"); compStr != "" {
		if val, err := strconv.ParseFloat(compStr, 64); err == nil {
			ub_compensation = &val
		}
	}

	ids := r.URL.Query()["ids"]
	req := GetRideRequestsRequest{
		IDs:          &ids,
		Compensation: ub_compensation,
	}
	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	ride_requests, err := a.ridesRepo.GetActiveRideRequests(ctx, req.IDs, req.Compensation)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := GetRideRequestsResponse{
		Requests: make([]GetRideRequestsResponseIndividual, len(ride_requests)),
	}

	for i, req := range ride_requests {
		response.Requests[i] = GetRideRequestsResponseIndividual{
			ID:              req.ID,
			PickupLocation:  req.PickupLocation,
			DropoffLocation: req.DropoffLocation,
			Compensation:    req.Compensation,
			CreatedAt:       req.CreatedAt,
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

type CreateRideDraftRequest struct {
	RequestIds []int64 `json:"ids" validate:"required"`
}

type CreateRideProposalIndividual struct {
	ID        int64  `json:"id"`
	RequestID int64  `json:"request_id"`
	Status    string `json:"status"`
	DriverID  int64  `json:"driver_id"`
	RideID    *int64 `json:"ride_id,omitempty"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

type CreateRideDraftResponse struct {
	ID        int64                          `json:"id"`
	Status    string                         `json:"status"`
	Proposals []CreateRideProposalIndividual `json:"proposals"`
}

func (a *api) createRideDraftHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	var req CreateRideDraftRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	// Get the account from the session
	account, err := a.accountsRepo.GetAccountFromSession(r.Context())
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}
	if account.Type != "driver" {
		a.errorResponse(w, r, http.StatusForbidden, fmt.Errorf("only drivers can create ride proposals"))
		return
	}

	// Create ride proposals
	var proposals []*domain.ProposalDBModel
	for _, id := range req.RequestIds {
		proposal := domain.ProposalDBModel{
			RequestID: id,
			DriverID:  account.ID,
			Status:    "pending",
		}
		proposals = append(proposals, &proposal)
	}
	created_ride, created_proposals, err := a.ridesRepo.CreateRideAndProposals(ctx, proposals)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := CreateRideDraftResponse{
		ID:        created_ride.ID,
		Status:    created_ride.Status,
		Proposals: make([]CreateRideProposalIndividual, len(created_proposals)),
	}

	for i, prop := range created_proposals {
		response.Proposals[i] = CreateRideProposalIndividual{
			ID:        prop.ID,
			RequestID: prop.RequestID,
			Status:    prop.Status,
			DriverID:  prop.DriverID,
			RideID:    prop.RideID,
			CreatedAt: prop.CreatedAt,
			UpdatedAt: prop.UpdatedAt,
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}


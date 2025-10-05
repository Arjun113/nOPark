package api

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strconv"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/Arjun113/nOPark/internal/repository"
	"go.uber.org/zap"
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
	PassengerID     int64   `json:"passenger_id"`
	CreatedAt       string  `json:"created_at"`
}

type GetRideRequestsResponse struct {
	Requests []GetRideRequestsResponseIndividual `json:"requests"`
}

func (a *api) getRideRequestsHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	var ubCompensation *float64 = nil
	if compStr := r.URL.Query().Get("compensation"); compStr != "" {
		if val, err := strconv.ParseFloat(compStr, 64); err == nil {
			ubCompensation = &val
		}
	}

	ids := r.URL.Query()["ids"]
	req := GetRideRequestsRequest{
		IDs:          &ids,
		Compensation: ubCompensation,
	}
	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	rideRequests, err := a.ridesRepo.GetActiveRideRequests(ctx, req.IDs, req.Compensation)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := GetRideRequestsResponse{
		Requests: make([]GetRideRequestsResponseIndividual, len(rideRequests)),
	}

	for i, req := range rideRequests {
		response.Requests[i] = GetRideRequestsResponseIndividual{
			ID:              req.ID,
			PickupLocation:  req.PickupLocation,
			DropoffLocation: req.DropoffLocation,
			Compensation:    req.Compensation,
			PassengerID:     req.PassengerID,
			CreatedAt:       req.CreatedAt,
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

type CreateRideDraftRequest struct {
	RequestIds []int64 `json:"request_ids" validate:"required"`
}

type CreateRideProposalIndividual struct {
	ID        int64  `json:"id"`
	RequestID int64  `json:"request_id"`
	Status    string `json:"status"`
	DriverID  int64  `json:"driver_id"`
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

	// Check if any of the requests already have an in-progress or completed ride
	for _, id := range req.RequestIds {
		rides, err := a.ridesRepo.GetRideByRequestID(ctx, id)
		if err != nil {
			a.errorResponse(w, r, http.StatusInternalServerError, err)
			return
		}
		if len(rides) > 0 {
			for _, ride := range rides {
				// Check if the ride is already in progress
				if ride.Status == "in_progress" || ride.Status == "completed" {
					a.errorResponse(w, r, http.StatusConflict, fmt.Errorf("a ride is already in progress or completed for request ID %d", id))
					return
				}
			}
		}
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
	newRide, newProposals, err := a.ridesRepo.CreateRideAndProposals(ctx, proposals)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	for _, proposal := range newProposals {
		request, err := a.ridesRepo.GetRequestByID(ctx, proposal.RequestID)
		if err != nil {
			a.logger.Error("Failed to get request for notification",
				zap.Error(err),
				zap.Int64("request_id", proposal.RequestID))
			continue
		}

		driver, err := a.accountsRepo.GetAccountByID(ctx, proposal.DriverID)
		if err != nil {
			a.logger.Error("Failed to get driver for notification",
				zap.Error(err),
				zap.Int64("driver_id", proposal.DriverID))
			continue
		}

		notification := &domain.NotificationDBModel{
			NotificationType: domain.NotificationTypeRideRequest,
			NotificationMessage: fmt.Sprintf("New ride proposal from %s %s for your request: %s to %s",
				driver.FirstName, driver.LastName,
				request.PickupLocation, request.DropoffLocation),
			AccountID: request.PassengerID,
		}

		_, err = a.notificationsRepo.CreateNotification(ctx, notification)
		if err != nil {
			a.logger.Error("Failed to create notification for passenger",
				zap.Error(err),
				zap.Int64("passenger_id", request.PassengerID),
				zap.Int64("proposal_id", proposal.ID))
		}
	}

	response := CreateRideDraftResponse{
		ID:        newRide.ID,
		Status:    newRide.Status,
		Proposals: make([]CreateRideProposalIndividual, len(newProposals)),
	}

	for i, prop := range newProposals {
		response.Proposals[i] = CreateRideProposalIndividual{
			ID:        prop.ID,
			RequestID: prop.RequestID,
			Status:    prop.Status,
			DriverID:  prop.DriverID,
			CreatedAt: prop.CreatedAt,
			UpdatedAt: prop.UpdatedAt,
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

type ConfirmRideProposalRequest struct {
	ProposalID int64  `json:"proposal_id" validate:"required"`
	Confirm    string `json:"confirm" validate:"required,oneof=accept reject"`
}

type ConfirmRideProposalResponse struct {
	ID             int64  `json:"id"`
	RequestID      int64  `json:"request_id"`
	ProposalStatus string `json:"proposal_status"`
	RideStatus     string `json:"ride_status"`
	DriverID       int64  `json:"driver_id"`
	RideID         int64  `json:"ride_id,omitempty"`
	CreatedAt      string `json:"created_at"`
	UpdatedAt      string `json:"updated_at"`
}

func (a *api) confirmRideProposalHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	var req ConfirmRideProposalRequest
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
		a.errorResponse(w, r, http.StatusForbidden, fmt.Errorf("only passengers can respond to ride proposals"))
		return
	}

	proposal, err := a.ridesRepo.GetProposalByID(ctx, req.ProposalID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if proposal.Status != "pending" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("proposal is not in pending state"))
		return
	}

	request, err := a.ridesRepo.GetRequestByID(ctx, proposal.RequestID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if account.ID != request.PassengerID {
		a.errorResponse(w, r, http.StatusForbidden, fmt.Errorf("you are not authorized to respond to this proposal"))
		return
	}

	proposal, err = a.ridesRepo.ConfirmRideProposal(ctx, proposal, req.Confirm)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	ride, err := a.ridesRepo.GetRideByID(ctx, proposal.RideID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	if ride.Status == "in_progress" {
		_, proposals, err := a.ridesRepo.GetRideAndProposals(ctx, ride.ID)
		if err != nil {
			a.logger.Error("Failed to get ride proposals for notifications",
				zap.Error(err),
				zap.Int64("ride_id", ride.ID))
		} else {
			driver, err := a.accountsRepo.GetAccountByID(ctx, proposal.DriverID)
			if err != nil {
				a.logger.Error("Failed to get driver for ride confirmation notification",
					zap.Error(err),
					zap.Int64("driver_id", proposal.DriverID))
			} else {
				for _, prop := range proposals {
					if prop.Status == "accepted" {
						request, err := a.ridesRepo.GetRequestByID(ctx, prop.RequestID)
						if err != nil {
							a.logger.Error("Failed to get request for ride confirmation notification",
								zap.Error(err),
								zap.Int64("request_id", prop.RequestID))
							continue
						}

						notification := &domain.NotificationDBModel{
							NotificationType: domain.NotificationTypeRideRequest,
							NotificationMessage: fmt.Sprintf("Your ride has been confirmed! Driver %s %s will pick you up at %s",
								driver.FirstName, driver.LastName, request.PickupLocation),
							AccountID: request.PassengerID,
						}

						_, err = a.notificationsRepo.CreateNotification(ctx, notification)
						if err != nil {
							a.logger.Error("Failed to create ride confirmation notification for passenger",
								zap.Error(err),
								zap.Int64("passenger_id", request.PassengerID),
								zap.Int64("ride_id", ride.ID))
						}
					}
				}
			}
		}
	}

	response := ConfirmRideProposalResponse{
		ID:             proposal.ID,
		ProposalStatus: proposal.Status,
		RideStatus:     ride.Status,
		DriverID:       proposal.DriverID,
		RideID:         ride.ID,
		CreatedAt:      proposal.CreatedAt,
		UpdatedAt:      proposal.UpdatedAt,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

type GetRideSummaryRequest struct {
	RideID int64 `json:"ride_id" validate:"required"`
}

type GetRideRequestIndividual struct {
	ID              int64   `json:"id"`
	PickupLocation  string  `json:"pickup_location"`
	DropoffLocation string  `json:"dropoff_location"`
	Compensation    float64 `json:"compensation"`
	PassengerID     int64   `json:"passenger_id"`
}

type GetRideProposalIndividual struct {
	ID       int64                    `json:"id"`
	Status   string                   `json:"status"`
	DriverID int64                    `json:"driver_id"`
	Request  GetRideRequestIndividual `json:"request"`
}

type GetRideSummaryResponse struct {
	ID        int64                       `json:"id"`
	Status    string                      `json:"status"`
	Proposals []GetRideProposalIndividual `json:"proposals"`
}

func (a *api) getRideSummaryHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	isAllowed := false
	var rideID *int64 = nil

	session, ok := repository.GetSessionFromContext(r.Context())
	if !ok {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to get session from context"))
		return
	}

	if rideStr := r.URL.Query().Get("ride_id"); rideStr != "" {
		if val, err := strconv.ParseInt(rideStr, 10, 64); err == nil {
			rideID = &val
		}
	}
	if rideID == nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("ride_id is required"))
		return
	}

	req := GetRideSummaryRequest{
		RideID: *rideID,
	}
	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	ride, proposals, err := a.ridesRepo.GetRideAndProposals(ctx, req.RideID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := GetRideSummaryResponse{
		ID:        ride.ID,
		Status:    ride.Status,
		Proposals: make([]GetRideProposalIndividual, len(proposals)),
	}

	for i, proposal := range proposals {
		rideRequest, err := a.ridesRepo.GetRequestByID(ctx, proposal.RequestID)
		if err != nil {
			a.errorResponse(w, r, http.StatusInternalServerError, err)
			return
		}

		response.Proposals[i] = GetRideProposalIndividual{
			ID:       proposal.ID,
			Status:   proposal.Status,
			DriverID: proposal.DriverID,
			Request: GetRideRequestIndividual{
				ID:              rideRequest.ID,
				PickupLocation:  rideRequest.PickupLocation,
				DropoffLocation: rideRequest.DropoffLocation,
				Compensation:    rideRequest.Compensation,
				PassengerID:     rideRequest.PassengerID,
			},
		}

		if rideRequest.PassengerID == session.AccountID || proposal.DriverID == session.AccountID {
			isAllowed = true
		}
	}

	// Check permissions
	if !isAllowed {
		a.errorResponse(w, r, http.StatusForbidden, fmt.Errorf("you do not have permission to view this ride summary"))
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

type CompensationEstimateRequest struct {
	StartLatitude  float64 `json:"start_latitude" validate:"required,number"`
	StartLongitude float64 `json:"start_longitude" validate:"required,number"`
	EndLatitude    float64 `json:"end_latitude" validate:"required,number"`
	EndLongitude   float64 `json:"end_longitude" validate:"required,number"`
}

type CompensationEstimateResponse struct {
	DistanceKm    float64 `json:"distance_km"`
	EstimatedComp float64 `json:"estimated_comp"`
}

func (a *api) compensationEstimateHandler(w http.ResponseWriter, r *http.Request) {

	var req CompensationEstimateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	distance := domain.CalculateHaversineDistance(req.StartLatitude, req.StartLongitude, req.EndLatitude, req.EndLongitude)

	estimatedPrice := domain.BaseFare + (distance * domain.PricePerKm)

	response := CompensationEstimateResponse{
		DistanceKm:    math.Round(distance*100) / 100,
		EstimatedComp: math.Round(estimatedPrice*100) / 100,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

type CompleteRideRequest struct {
	RideID int64 `json:"ride_id" validate:"required"`
}

func (a *api) completeRideHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	account, err := a.accountsRepo.GetAccountFromSession(r.Context())
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}
	if account.Type != "driver" {
		a.errorResponse(w, r, http.StatusForbidden, fmt.Errorf("only drivers can complete rides"))
		return
	}

	var req CompleteRideRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}
	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	ride, err := a.ridesRepo.GetRideByID(ctx, req.RideID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if ride.Status != "in_progress" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("ride is not in progress"))
		return
	}

	if err := a.ridesRepo.CompleteRide(ctx, ride.ID); err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

type RideHistoryItem struct {
	RideID    int64                      `json:"ride_id"`
	Status    string                     `json:"status"`
	DriverID  int64                      `json:"driver_id,omitempty"`
	Requests  []GetRideRequestIndividual `json:"requests"`
	CreatedAt string                     `json:"created_at"`
	UpdatedAt string                     `json:"updated_at"`
}

type GetRideHistoryResponse struct {
	Rides []RideHistoryItem `json:"rides"`
}

func (a *api) getRideHistoryHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	account, err := a.accountsRepo.GetAccountFromSession(r.Context())
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}

	rides, err := a.ridesRepo.GetPreviousRides(ctx, account.ID, account.Type, 5, 0)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := GetRideHistoryResponse{
		Rides: make([]RideHistoryItem, len(rides)),
	}
	for i, ride := range rides {
		_, proposals, err := a.ridesRepo.GetRideAndProposals(ctx, ride.ID)
		if err != nil {
			a.errorResponse(w, r, http.StatusInternalServerError, err)
			return
		}

		response.Rides[i] = RideHistoryItem{
			RideID:    ride.ID,
			Status:    ride.Status,
			DriverID:  0,
			Requests:  make([]GetRideRequestIndividual, 0),
			CreatedAt: ride.CreatedAt,
			UpdatedAt: ride.UpdatedAt,
		}
		if ride.Status == "in_progress" || ride.Status == "completed" {
			for _, proposal := range proposals {
				if proposal.Status != "accepted" {
					continue
				}

				request, err := a.ridesRepo.GetRequestByID(ctx, proposal.RequestID)
				if err != nil {
					a.errorResponse(w, r, http.StatusInternalServerError, err)
					return
				}

				rideRequest := GetRideRequestIndividual{
					ID:              request.ID,
					PickupLocation:  request.PickupLocation,
					DropoffLocation: request.DropoffLocation,
					Compensation:    request.Compensation,
					PassengerID:     request.PassengerID,
				}

				response.Rides[i].Requests = append(response.Rides[i].Requests, rideRequest)
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

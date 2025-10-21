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
	"github.com/Arjun113/nOPark/internal/utils"
	"go.uber.org/zap"
)

type CreateRideRequestRequest struct {
	PickupLocation   string  `json:"pickup_location,omitempty"`
	PickupLatitude   float64 `json:"pickup_latitude" validate:"required,number"`
	PickupLongitude  float64 `json:"pickup_longitude" validate:"required,number"`
	DropoffLocation  string  `json:"dropoff_location" validate:"required"`
	DropoffLatitude  float64 `json:"dropoff_latitude" validate:"required,number"`
	DropoffLongitude float64 `json:"dropoff_longitude" validate:"required,number"`
	Compensation     float64 `json:"compensation" validate:"required,gt=0"`
}

type CreateRideRequestResponse struct {
	ID               int64   `json:"id"`
	PickupLocation   string  `json:"pickup_location"`
	PickupLatitude   float64 `json:"pickup_latitude"`
	PickupLongitude  float64 `json:"pickup_longitude"`
	DropoffLocation  string  `json:"dropoff_location"`
	DropoffLatitude  float64 `json:"dropoff_latitude"`
	DropoffLongitude float64 `json:"dropoff_longitude"`
	Compensation     float64 `json:"compensation"`
	PassengerID      int64   `json:"passenger_id"`
	CreatedAt        string  `json:"created_at"`
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

	existing_requests, err := a.ridesRepo.GetActiveRideRequests(ctx, nil, nil, &account.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	if len(existing_requests) > 0 {
		a.errorResponse(w, r, http.StatusConflict, fmt.Errorf("active ride request already exists for this passenger"))
		return
	}

	request := &domain.RequestDBModel{
		PickupLocation:   req.PickupLocation,
		PickupLatitude:   req.PickupLatitude,
		PickupLongitude:  req.PickupLongitude,
		DropoffLocation:  req.DropoffLocation,
		DropoffLatitude:  req.DropoffLatitude,
		DropoffLongitude: req.DropoffLongitude,
		Compensation:     req.Compensation,
		PassengerID:      account.ID,
	}

	createdRequest, err := a.ridesRepo.CreateRideRequest(ctx, request)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := CreateRideRequestResponse{
		ID:               createdRequest.ID,
		PickupLocation:   createdRequest.PickupLocation,
		PickupLatitude:   createdRequest.PickupLatitude,
		PickupLongitude:  createdRequest.PickupLongitude,
		DropoffLocation:  createdRequest.DropoffLocation,
		DropoffLatitude:  createdRequest.DropoffLatitude,
		DropoffLongitude: createdRequest.DropoffLongitude,
		Compensation:     createdRequest.Compensation,
		PassengerID:      createdRequest.PassengerID,
		CreatedAt:        createdRequest.CreatedAt,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

type GetRideRequestsRequest struct {
	IDs          *[]string `json:"ids,omitempty"`
	Compensation *float64  `json:"compensation,omitempty"`
	DropoffLat   float64   `json:"dropoff_lat" validate:"required,min=-90,max=90"`
	DropoffLon   float64   `json:"dropoff_lon" validate:"required,min=-180,max=180"`
	DistanceM    *float64  `json:"distance_m,omitempty"`
	TimeS        *int64    `json:"time_s,omitempty"`
}

type GetRideRequestsResponseIndividual struct {
	ID               int64    `json:"id"`
	PickupLocation   string   `json:"pickup_location"`
	PickupLatitude   float64  `json:"pickup_latitude"`
	PickupLongitude  float64  `json:"pickup_longitude"`
	DropoffLocation  string   `json:"dropoff_location"`
	DropoffLatitude  float64  `json:"dropoff_latitude"`
	DropoffLongitude float64  `json:"dropoff_longitude"`
	DetourRoute      *string  `json:"detour_route,omitempty"`
	DetourTimeS      *int64   `json:"detour_time_s,omitempty"`
	DetourDistanceM  *float64 `json:"detour_distance_m,omitempty"`
	Compensation     float64  `json:"compensation"`
	PassengerID      int64    `json:"passenger_id"`
	CreatedAt        string   `json:"created_at"`
}

type GetRideRequestsResponse struct {
	Polyline string                              `json:"polyline"`
	Requests []GetRideRequestsResponseIndividual `json:"requests"`
}

func (a *api) getRideRequestsHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	account, err := a.accountsRepo.GetAccountFromSession(r.Context())
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}

	switch account.Type {
	case "driver":
		a.getRideRequestsAsDriver(ctx, account, w, r)
	case "passenger":
		a.getRideRequestsAsPassenger(ctx, account, w, r)
	default:
		a.errorResponse(w, r, http.StatusForbidden, fmt.Errorf("only drivers and passengers can view ride requests"))
	}
}

func (a *api) getRideRequestsAsPassenger(ctx context.Context, account *domain.AccountDBModel, w http.ResponseWriter, r *http.Request) {
	rideRequests, err := a.ridesRepo.GetActiveRideRequests(ctx, nil, nil, &account.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := GetRideRequestsResponse{
		Requests: make([]GetRideRequestsResponseIndividual, len(rideRequests)),
	}

	for i, rideRequest := range rideRequests {
		response.Requests[i] = GetRideRequestsResponseIndividual{
			ID:               rideRequest.ID,
			PickupLocation:   rideRequest.PickupLocation,
			PickupLatitude:   rideRequest.PickupLatitude,
			PickupLongitude:  rideRequest.PickupLongitude,
			DropoffLocation:  rideRequest.DropoffLocation,
			DropoffLatitude:  rideRequest.DropoffLatitude,
			DropoffLongitude: rideRequest.DropoffLongitude,
			Compensation:     rideRequest.Compensation,
			PassengerID:      rideRequest.PassengerID,
			CreatedAt:        rideRequest.CreatedAt,
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func (a *api) getRideRequestsAsDriver(ctx context.Context, account *domain.AccountDBModel, w http.ResponseWriter, r *http.Request) {

	// Parse query parameters
	ubCompensation, _ := utils.FloatFromQueryParam(r, "compensation", true)
	dropoffLat, err := utils.FloatFromQueryParam(r, "dropoff_lat", false)
	if err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("dropoff_lat parameter is required and must be a valid float"))
		return
	}
	dropoffLon, err := utils.FloatFromQueryParam(r, "dropoff_lon", false)
	if err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("dropoff_lon parameter is required and must be a valid float"))
		return
	}
	distanceM, _ := utils.FloatFromQueryParam(r, "distance_m", true)
	timeS, _ := utils.IntFromQueryParam(r, "time_s", true)
	ids := r.URL.Query()["ids"]

	requestParams := GetRideRequestsRequest{
		IDs:          &ids,
		Compensation: ubCompensation,
		DropoffLat:   *dropoffLat,
		DropoffLon:   *dropoffLon,
		DistanceM:    distanceM,
		TimeS:        timeS,
	}
	if err := a.validateRequest(requestParams); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	if account.CurrentLongitude == nil || account.CurrentLatitude == nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("current location required to calculate detour distance and time"))
		return
	}

	rideRequests, err := a.ridesRepo.GetActiveRideRequests(ctx, nil, requestParams.Compensation, nil)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Calculate driver's route
	start := domain.Coordinates{Lat: *account.CurrentLatitude, Lon: *account.CurrentLongitude}
	dest := domain.Coordinates{Lat: requestParams.DropoffLat, Lon: requestParams.DropoffLon}
	driverRoute, err := a.mapsRepo.GetDirectRoute(ctx, start, dest)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("error calculating driver's route"))
		return
	}

	response := GetRideRequestsResponse{
		Polyline: driverRoute.Polyline,
		Requests: make([]GetRideRequestsResponseIndividual, 0),
	}

	// Calculate distance and time for each request
	for _, rideRequest := range rideRequests {
		detourRoute, err := a.mapsRepo.GetMultistopRoute(ctx,
			start,
			[]domain.Coordinates{{Lat: rideRequest.PickupLatitude, Lon: rideRequest.PickupLongitude}},
			dest,
		)
		if err != nil {
			a.errorResponse(w, r, http.StatusInternalServerError, err)
			return
		}
		detourTimeDelta := detourRoute.Duration - driverRoute.Duration
		detourDistanceDelta := detourRoute.Distance - driverRoute.Distance

		if requestParams.DistanceM != nil && detourDistanceDelta > *requestParams.DistanceM {
			continue
		}
		if requestParams.TimeS != nil && detourTimeDelta > *requestParams.TimeS {
			continue
		}

		response.Requests = append(response.Requests, GetRideRequestsResponseIndividual{
			ID:               rideRequest.ID,
			PickupLocation:   rideRequest.PickupLocation,
			PickupLatitude:   rideRequest.PickupLatitude,
			PickupLongitude:  rideRequest.PickupLongitude,
			DropoffLocation:  rideRequest.DropoffLocation,
			DropoffLatitude:  rideRequest.DropoffLatitude,
			DropoffLongitude: rideRequest.DropoffLongitude,
			DetourTimeS:      &detourTimeDelta,
			DetourDistanceM:  &detourDistanceDelta,
			DetourRoute:      &detourRoute.Polyline,
			Compensation:     rideRequest.Compensation,
			PassengerID:      rideRequest.PassengerID,
			CreatedAt:        rideRequest.CreatedAt,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

type CreateRideDraftRequest struct {
	RequestIds     []int64 `json:"request_ids" validate:"required"`
	DestinationLat float64 `json:"destination_lat" validate:"required,min=-90,max=90"`
	DestinationLon float64 `json:"destination_lon" validate:"required,min=-180,max=180"`
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
	ID             int64                          `json:"id"`
	Status         string                         `json:"status"`
	DestinationLat float64                        `json:"destination_lat"`
	DestinationLon float64                        `json:"destination_lon"`
	Proposals      []CreateRideProposalIndividual `json:"proposals"`
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
				if ride.Status == "in_progress" || ride.Status == "completed" || ride.Status == "awaiting_confirmation" {
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

	// Pass destination coordinates from request
	newRide, newProposals, err := a.ridesRepo.CreateRideAndProposals(ctx, proposals, req.DestinationLat, req.DestinationLon)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Create Notif for each passenger
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

		notificationPayload := fmt.Sprintf(`{"proposal_id": %d, "notification": "%s"}`, proposal.ID, domain.NotificationRideCreated)
		notification := &domain.NotificationDBModel{
			NotificationType: domain.NotificationTypeRideUpdates,
			NotificationMessage: fmt.Sprintf("New ride proposal from %s %s for your request: %s to %s",
				driver.FirstName, driver.LastName,
				request.PickupLocation, request.DropoffLocation),
			AccountID: request.PassengerID,
			Payload:   &notificationPayload,
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
		ID:             newRide.ID,
		Status:         newRide.Status,
		DestinationLat: newRide.DestinationLatitude,
		DestinationLon: newRide.DestinationLongitude,
		Proposals:      make([]CreateRideProposalIndividual, len(newProposals)),
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

type GetRideProposalsRequest struct {
	ProposalID int64 `json:"proposal_id"`
}

type GetRideProposalResponse struct {
	ID        int64   `json:"id"`
	RequestID int64   `json:"request_id"`
	Status    string  `json:"status"`
	DriverID  int64   `json:"driver_id"`
	RideID    int64   `json:"ride_id"`
	Polyline  string  `json:"polyline"`
	Duration  int64   `json:"duration"`
	Distance  float64 `json:"distance"`
	CreatedAt string  `json:"created_at"`
	UpdatedAt string  `json:"updated_at"`
}

func (a *api) GetRideProposalsHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	// Check permsissions
	account, err := a.accountsRepo.GetAccountFromSession(r.Context())
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}
	if account.Type != "passenger" {
		a.errorResponse(w, r, http.StatusForbidden, fmt.Errorf("only passengers can view ride proposals"))
		return
	}

	// Get from params
	proposalID, err := utils.IntFromQueryParam(r, "proposal_id", false)
	if err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid proposal_id"))
		return
	}

	// Validate request input
	requestParams := GetRideProposalsRequest{
		ProposalID: *proposalID,
	}
	if err := a.validateRequest(requestParams); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	// Get corresponding proposal and request object
	proposal, err := a.ridesRepo.GetProposalByID(ctx, requestParams.ProposalID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	request, err := a.ridesRepo.GetRequestByID(ctx, proposal.RequestID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if request.PassengerID != account.ID {
		a.errorResponse(w, r, http.StatusForbidden, fmt.Errorf("you are not authorized to view this proposal"))
		return
	}

	driver, err := a.accountsRepo.GetAccountByID(ctx, proposal.DriverID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if driver.CurrentLatitude == nil || driver.CurrentLongitude == nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("driver's current location is not available"))
		return
	}

	// Gather pickup points
	_, proposals, err := a.ridesRepo.GetRideAndProposals(ctx, proposal.RideID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Add pickup point of all proposals except rejected ones
	var waypoints []domain.Coordinates
	for _, prop := range proposals {
		if prop.Status == "rejected" {
			continue
		}

		req, err := a.ridesRepo.GetRequestByID(ctx, prop.RequestID)
		if err != nil {
			a.errorResponse(w, r, http.StatusInternalServerError, err)
			return
		}

		waypoints = append(waypoints, domain.Coordinates{
			Lat: req.PickupLatitude,
			Lon: req.PickupLongitude,
		})
	}

	// Start from driver's location and end at any proposal's dropoff location
	route, err := a.mapsRepo.GetRouteFromWaypoints(ctx,
		domain.Coordinates{Lat: *driver.CurrentLatitude, Lon: *driver.CurrentLongitude},
		waypoints,
		domain.Coordinates{Lat: request.DropoffLatitude, Lon: request.DropoffLongitude},
	)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("%s", "error calculating route with waypoints: "+err.Error()))
		return
	}

	response := GetRideProposalResponse{
		ID:        proposal.ID,
		RequestID: proposal.RequestID,
		Status:    proposal.Status,
		DriverID:  proposal.DriverID,
		RideID:    proposal.RideID,
		Polyline:  route.Polyline,
		Duration:  route.Duration,
		Distance:  route.Distance,
		CreatedAt: proposal.CreatedAt,
		UpdatedAt: proposal.UpdatedAt,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
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

	// Notification to passenger and driver
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
				// Notification to driver about accepted ride
				notificationPayload := fmt.Sprintf(`{"ride_id": %d, "notification": "%s"}`, ride.ID, domain.NotificationRideFinalized)
				notification := &domain.NotificationDBModel{
					NotificationType:    domain.NotificationTypeRideUpdates,
					NotificationMessage: "Your ride trip has been accepted!",
					AccountID:           driver.ID,
					Payload:             &notificationPayload,
				}

				_, err = a.notificationsRepo.CreateNotification(ctx, notification)
				if err != nil {
					a.logger.Error("Failed to create ride confirmation notification for driver",
						zap.Error(err),
						zap.Int64("driver_id", driver.ID),
						zap.Int64("ride_id", ride.ID))
				}

				// Notification to all passengers about accepted ride
				for _, prop := range proposals {
					if prop.Status == "accepted" {
						request, err := a.ridesRepo.GetRequestByID(ctx, prop.RequestID)
						if err != nil {
							a.logger.Error("Failed to get request for ride confirmation notification",
								zap.Error(err),
								zap.Int64("request_id", prop.RequestID))
							continue
						}

						notificationPayload := fmt.Sprintf(`{"ride_id": %d, "notification": "%s"}`, ride.ID, domain.NotificationRideFinalized)
						notification := &domain.NotificationDBModel{
							NotificationType: domain.NotificationTypeRideUpdates,
							NotificationMessage: fmt.Sprintf("Your ride has been confirmed! Driver %s %s will be picking you up.",
								driver.FirstName, driver.LastName),
							AccountID: request.PassengerID,
							Payload:   &notificationPayload,
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
	} else if ride.Status == "rejected" {
		driver, err := a.accountsRepo.GetAccountByID(ctx, proposal.DriverID)
		if err != nil {
			a.logger.Error("Failed to get driver for ride rejection notification",
				zap.Error(err),
				zap.Int64("driver_id", proposal.DriverID))
		} else {
			// Notification to driver about rejected ride
			notificationPayload := fmt.Sprintf(`{"ride_id": %d, "notification": "%s"}`, ride.ID, domain.NotificationRideFinalized)
			notification := &domain.NotificationDBModel{
				NotificationType:    domain.NotificationTypeRideUpdates,
				NotificationMessage: "Your planned ride has been rejected.",
				AccountID:           driver.ID,
				Payload:             &notificationPayload,
			}

			_, err = a.notificationsRepo.CreateNotification(ctx, notification)
			if err != nil {
				a.logger.Error("Failed to create ride rejection notification for driver",
					zap.Error(err),
					zap.Int64("driver_id", driver.ID),
					zap.Int64("ride_id", ride.ID))
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
	ID               int64   `json:"id"`
	PickupLocation   string  `json:"pickup_location"`
	PickupLatitude   float64 `json:"pickup_latitude"`
	PickupLongitude  float64 `json:"pickup_longitude"`
	DropoffLocation  string  `json:"dropoff_location"`
	DropoffLatitude  float64 `json:"dropoff_latitude"`
	DropoffLongitude float64 `json:"dropoff_longitude"`
	Compensation     float64 `json:"compensation"`
	PassengerID      int64   `json:"passenger_id"`
}

type GetRideProposalIndividual struct {
	ID       int64                    `json:"id"`
	Status   string                   `json:"status"`
	DriverID int64                    `json:"driver_id"`
	Request  GetRideRequestIndividual `json:"request"`
}

type GetRideSummaryResponse struct {
	ID             int64                       `json:"id"`
	Status         string                      `json:"status"`
	DestinationLat float64                     `json:"destination_lat"`
	DestinationLon float64                     `json:"destination_lon"`
	Proposals      []GetRideProposalIndividual `json:"proposals"`
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
		ID:             ride.ID,
		Status:         ride.Status,
		DestinationLat: ride.DestinationLatitude,
		DestinationLon: ride.DestinationLongitude,
		Proposals:      make([]GetRideProposalIndividual, len(proposals)),
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
				ID:               rideRequest.ID,
				PickupLocation:   rideRequest.PickupLocation,
				PickupLatitude:   rideRequest.PickupLatitude,
				PickupLongitude:  rideRequest.PickupLongitude,
				DropoffLocation:  rideRequest.DropoffLocation,
				DropoffLatitude:  rideRequest.DropoffLatitude,
				DropoffLongitude: rideRequest.DropoffLongitude,
				Compensation:     rideRequest.Compensation,
				PassengerID:      rideRequest.PassengerID,
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

type ReachPickupRequest struct {
	RideID           int64   `json:"ride_id" validate:"required"`
	CurrentLatitude  float64 `json:"current_lat" validate:"required,min=-90,max=90"`
	CurrentLongitude float64 `json:"current_lon" validate:"required,min=-180,max=180"`
}

func (a *api) reachPickupHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	account, err := a.accountsRepo.GetAccountFromSession(ctx)
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}
	if account.Type != "driver" {
		a.errorResponse(w, r, http.StatusForbidden, fmt.Errorf("only drivers can update their location"))
		return
	}

	// Parse input
	var req ReachPickupRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}
	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	// Check ride exists and is in progress
	ride, err := a.ridesRepo.GetRideByID(ctx, req.RideID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if ride.Status != "in_progress" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("ride is not in progress"))
		return
	}

	// Get Request
	requests, err := a.ridesRepo.GetUnvisitedRequestsByRideID(ctx, req.RideID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if len(requests) == 0 {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("no unvisited requests found for this ride"))
		return
	}

	var closest *domain.RequestDBModel
	var closestDistance float64 = -1
	for _, request := range requests {
		distance := domain.CalculateHaversineDistance(req.CurrentLatitude, req.CurrentLongitude, request.PickupLatitude, request.PickupLongitude)
		if closestDistance == -1 || distance < closestDistance {
			closestDistance = distance
			closest = request
		}
	}
	if closestDistance > 1000 {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("you are too far from the nearest pickup location (%.2f meters)", closestDistance))
		return
	}

	// Mark request as visited
	if err := a.ridesRepo.MarkRequestAsVisited(ctx, closest.ID); err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
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

	_, proposals, err := a.ridesRepo.GetRideAndProposals(ctx, ride.ID)
	if err != nil {
		a.logger.Error("Failed to get ride proposals for completion notifications",
			zap.Error(err),
			zap.Int64("ride_id", ride.ID))
	} else {
		for _, proposal := range proposals {
			if proposal.Status == "accepted" {
				request, err := a.ridesRepo.GetRequestByID(ctx, proposal.RequestID)
				if err != nil {
					a.logger.Error("Failed to get request for ride completion notification",
						zap.Error(err),
						zap.Int64("request_id", proposal.RequestID))
					continue
				}

				notificationPayload := fmt.Sprintf(`{"ride_id": %d, "notification": "%s"}`, ride.ID, domain.NotificationRideCompleted)
				notification := &domain.NotificationDBModel{
					NotificationType:    domain.NotificationTypeRideUpdates,
					NotificationMessage: "Your ride has been completed! We hope you had a great experience.",
					AccountID:           request.PassengerID,
					Payload:             &notificationPayload,
				}

				_, err = a.notificationsRepo.CreateNotification(ctx, notification)
				if err != nil {
					a.logger.Error("Failed to create ride completion notification for passenger",
						zap.Error(err),
						zap.Int64("passenger_id", request.PassengerID),
						zap.Int64("ride_id", ride.ID))
				}
			}
		}
	}
	w.WriteHeader(http.StatusNoContent)

}

type RideHistoryItem struct {
	RideID         int64                      `json:"ride_id"`
	DestinationLat float64                    `json:"destination_lat"`
	DestinationLon float64                    `json:"destination_lon"`
	Status         string                     `json:"status"`
	DriverID       int64                      `json:"driver_id,omitempty"`
	Requests       []GetRideRequestIndividual `json:"requests"`
	CreatedAt      string                     `json:"created_at"`
	UpdatedAt      string                     `json:"updated_at"`
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
			RideID:         ride.ID,
			Status:         ride.Status,
			DestinationLat: ride.DestinationLatitude,
			DestinationLon: ride.DestinationLongitude,
			DriverID:       0,
			Requests:       make([]GetRideRequestIndividual, 0),
			CreatedAt:      ride.CreatedAt,
			UpdatedAt:      ride.UpdatedAt,
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
					ID:               request.ID,
					PickupLocation:   request.PickupLocation,
					PickupLatitude:   request.PickupLatitude,
					PickupLongitude:  request.PickupLongitude,
					DropoffLocation:  request.DropoffLocation,
					DropoffLatitude:  request.DropoffLatitude,
					DropoffLongitude: request.DropoffLongitude,
					Compensation:     request.Compensation,
					PassengerID:      request.PassengerID,
				}

				response.Rides[i].Requests = append(response.Rides[i].Requests, rideRequest)
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

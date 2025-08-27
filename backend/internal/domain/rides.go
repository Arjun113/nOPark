package domain

import (
	"context"
	"math"
)

const BaseFare = 2
const PricePerKm = 0.25

type RidesRepository interface {
	CreateRideRequest(ctx context.Context, req *RequestDBModel) (*RequestDBModel, error)
	GetActiveRideRequests(ctx context.Context, ids *[]string, ub_compensation *float64) ([]*RequestDBModel, error)
	CreateRideAndProposals(ctx context.Context, proposals []*ProposalDBModel) (*RideDBModel, []*ProposalDBModel, error)
	GetRideAndProposals(ctx context.Context, rideID int64) (*RideDBModel, []*ProposalDBModel, error)
	ConfirmRideProposal(ctx context.Context, proposal *ProposalDBModel, confirm string) (*ProposalDBModel, error)
	GetRideByID(ctx context.Context, rideID int64) (*RideDBModel, error)
	GetProposalByID(ctx context.Context, proposalID int64) (*ProposalDBModel, error)
	GetRequestByID(ctx context.Context, requestID int64) (*RequestDBModel, error)
}

type RideDBModel struct {
	ID        int64
	Status    string
	CreatedAt string
	UpdatedAt string
}

type RequestDBModel struct {
	ID                      int64
	PickupLocation          string
	DropoffLocation         string
	Compensation            float64
	PassengerID             int64
	RideID                  *int64
	AreNotificationsCreated bool
	CreatedAt               string
}

type ProposalDBModel struct {
	ID        int64
	RequestID int64
	Status    string
	DriverID  int64
	RideID    int64
	CreatedAt string
	UpdatedAt string
}

func CalculateHaversineDistance(lat1, lng1, lat2, lng2 float64) float64 {
	const earthRadiusKm = 6371.0

	// Convert decimal degrees to radians
	lat1Rad := lat1 * math.Pi / 180
	lng1Rad := lng1 * math.Pi / 180
	lat2Rad := lat2 * math.Pi / 180
	lng2Rad := lng2 * math.Pi / 180

	// Haversine formula
	dlat := lat2Rad - lat1Rad
	dlng := lng2Rad - lng1Rad

	a := math.Sin(dlat/2)*math.Sin(dlat/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*
			math.Sin(dlng/2)*math.Sin(dlng/2)

	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return earthRadiusKm * c
}

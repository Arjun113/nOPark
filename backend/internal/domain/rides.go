package domain

import (
	"context"
)

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

package domain

import (
	"context"
)

type RidesRepository interface {
	CreateRide(ctx context.Context, ride *RideDBModel) (*RideDBModel, error)
	CreateRequest(ctx context.Context, req *RequestDBModel) (*RequestDBModel, error)
}

type RideDBModel struct {
	ID        int64  `json:"id"`
	Status    string `json:"status"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

type RequestDBModel struct {
	ID              int64   `json:"id"`
	PickupLocation  string  `json:"pickup_location"`
	DropoffLocation string  `json:"dropoff_location"`
	Compensation    float64 `json:"compensation"`
	PassengerID     int64   `json:"passenger_id"`
	RideID          int64   `json:"ride_id"`
	CreatedAt       string  `json:"created_at"`
}

type ProposalDBModel struct {
	ID        int64  `json:"id"`
	RequestID int64  `json:"request_id"`
	Status    string `json:"status"`
	DriverID  int64  `json:"driver_id"`
	RideID    *int64 `json:"ride_id,omitempty"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}
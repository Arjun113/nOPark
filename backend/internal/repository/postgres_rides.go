package repository

import (
	"context"

	"github.com/Arjun113/nOPark/internal/domain"
)

type postgresRidesRepository struct {
	conn Connection
}

func NewPostgresRides(conn Connection) domain.RidesRepository {
	return &postgresRidesRepository{conn: conn}
}

func (p *postgresRidesRepository) CreateRide(ctx context.Context, ride *domain.RideDBModel) (*domain.RideDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`INSERT INTO rides (status) 
		 VALUES ($1) 
		 RETURNING id, status, created_at, updated_at`,
		ride.Status)

	var rideModel domain.RideDBModel
	err := row.Scan(&rideModel.ID, &rideModel.Status, &rideModel.CreatedAt, &rideModel.UpdatedAt)
	if err != nil {
		return nil, err
	}

	return &rideModel, nil
}

func (p *postgresRidesRepository) CreateRequest(ctx context.Context, req *domain.RequestDBModel) (*domain.RequestDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`INSERT INTO requests (pickup_location, dropoff_location, compensation, passenger_id) 
		 VALUES ($1, $2, $3, $4) 
		 RETURNING id, pickup_location, dropoff_location, compensation, passenger_id, created_at`,
		req.PickupLocation, req.DropoffLocation, req.Compensation, req.PassengerID)

	var request domain.RequestDBModel
	err := row.Scan(&request.ID, &request.PickupLocation, &request.DropoffLocation, &request.Compensation, &request.PassengerID, &request.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &request, nil
}
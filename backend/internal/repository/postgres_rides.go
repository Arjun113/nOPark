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

func (p *postgresRidesRepository) CreateRideRequest(ctx context.Context, req *domain.RequestDBModel) (*domain.RequestDBModel, error) {
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

func (p *postgresRidesRepository) GetActiveRideRequests(ctx context.Context) ([]*domain.RequestDBModel, error) {
	rows, err := p.conn.Query(ctx,
		`SELECT id, pickup_location, dropoff_location, compensation, passenger_id, created_at 
		 FROM requests WHERE ride_id IS NULL`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var requests []*domain.RequestDBModel
	for rows.Next() {
		var req domain.RequestDBModel
		if err := rows.Scan(&req.ID, &req.PickupLocation, &req.DropoffLocation, &req.Compensation, &req.PassengerID, &req.CreatedAt); err != nil {
			return nil, err
		}
		requests = append(requests, &req)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return requests, nil
}
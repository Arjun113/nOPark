package repository

import (
	"context"
	"fmt"

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
		`INSERT INTO requests (pickup_location, dropoff_location, compensation, passenger_id, notifs_crtd) 
		 VALUES ($1, $2, $3, $4, $5) 
		 RETURNING id, pickup_location, dropoff_location, compensation, passenger_id, notifs_crtd, created_at`,
		req.PickupLocation, req.DropoffLocation, req.Compensation, req.PassengerID, false)

	var request domain.RequestDBModel
	err := row.Scan(&request.ID, &request.PickupLocation, &request.DropoffLocation, &request.Compensation, &request.PassengerID, &request.AreNotificationsCreated, &request.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &request, nil
}

func (p *postgresRidesRepository) GetActiveRideRequests(ctx context.Context, ids *[]string, ub_compensation *float64) ([]*domain.RequestDBModel, error) {
	query := `SELECT id, pickup_location, dropoff_location, compensation, passenger_id, notifs_crtd, created_at 
			  FROM requests 
			  WHERE ride_id IS NULL`
	args := []any{}
	argIdx := 1

	if ids != nil && len(*ids) > 0 {
		query += fmt.Sprintf(` AND id = ANY($%d)`, argIdx)
		args = append(args, *ids)
		argIdx++
	}
	if ub_compensation != nil && *ub_compensation >= 0 {
		query += fmt.Sprintf(` AND compensation <= $%d`, argIdx)
		args = append(args, *ub_compensation)
		argIdx++
	}

	rows, err := p.conn.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var requests []*domain.RequestDBModel
	for rows.Next() {
		var req domain.RequestDBModel
		if err := rows.Scan(&req.ID, &req.PickupLocation, &req.DropoffLocation, &req.Compensation, &req.PassengerID, &req.AreNotificationsCreated, &req.CreatedAt); err != nil {
			return nil, err
		}
		requests = append(requests, &req)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return requests, nil
}

func (p *postgresRidesRepository) CreateRideAndProposals(ctx context.Context, proposals []*domain.ProposalDBModel) (*domain.RideDBModel, []*domain.ProposalDBModel, error) {
	row := p.conn.QueryRow(ctx, `INSERT INTO rides DEFAULT VALUES RETURNING id, status, created_at, updated_at`)

	var ride domain.RideDBModel
	err := row.Scan(&ride.ID, &ride.Status, &ride.CreatedAt, &ride.UpdatedAt)
	if err != nil {
		return nil, nil, err
	}
	query := `INSERT INTO proposals (request_id, driver_id, status, ride_id)
		VALUES ($1, $2, $3, $4)
		RETURNING id, request_id, status, driver_id, ride_id, created_at, updated_at`

	var createdProposals []*domain.ProposalDBModel
	for _, proposal := range proposals {
		var createdProposal domain.ProposalDBModel
		row := p.conn.QueryRow(ctx, query,
			proposal.RequestID, proposal.DriverID, proposal.Status, ride.ID)

		err := row.Scan(&createdProposal.ID, &createdProposal.RequestID, &createdProposal.Status, &createdProposal.DriverID, &createdProposal.RideID, &createdProposal.CreatedAt, &createdProposal.UpdatedAt)
		if err != nil {
			return nil, nil, err
		}
		createdProposals = append(createdProposals, &createdProposal)
	}

	return &ride, createdProposals, nil
}


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

func (p *postgresRidesRepository) ConfirmRideProposal(ctx context.Context, proposal *domain.ProposalDBModel, confirm string) (*domain.ProposalDBModel, error) {
	var status string
	switch confirm {
	case "accept":
		status = "accepted"
	case "reject":
		status = "rejected"
	default:
		return nil, fmt.Errorf("invalid confirmation value: %s", confirm)
	}

	row := p.conn.QueryRow(ctx,
		`UPDATE proposals SET status = $1 WHERE id = $2 RETURNING id, request_id, status, driver_id, ride_id, created_at, updated_at`,
		status, proposal.ID)

	var updatedProposal domain.ProposalDBModel
	err := row.Scan(&updatedProposal.ID, &updatedProposal.RequestID, &updatedProposal.Status, &updatedProposal.DriverID, &updatedProposal.RideID, &updatedProposal.CreatedAt, &updatedProposal.UpdatedAt)
	if err != nil {
		return nil, err
	}

	row = p.conn.QueryRow(ctx,
		`SELECT COALESCE(count(id),0) FROM proposals WHERE ride_id = $1 AND status = 'pending'`,
		proposal.RideID)

	var pending_count int64
	err = row.Scan(&pending_count)
	if err != nil {
		return nil, err
	}

	// Update ride status if all proposals responded.
	if pending_count == 0 {
		row := p.conn.QueryRow(ctx,
			`SELECT COUNT(id), ARRAY_AGG(request_id)
			FROM proposals
			WHERE ride_id = $1 AND status = 'accepted'`,
			proposal.RideID,
		)

		var accepted_count int64
		var accepted_request_ids []int64
		err = row.Scan(&accepted_count, &accepted_request_ids)
		if err != nil {
			return nil, err
		}

		var ride_status string
		if accepted_count == 0 {
			ride_status = "rejected"
		} else {
			ride_status = "in_progress"

			// Update requests to be undiscoverable
			_, err = p.conn.Exec(ctx,
				`UPDATE requests SET ride_id = $1 WHERE id = ANY($2)`,
				proposal.RideID, accepted_request_ids)
			if err != nil {
				return nil, err
			}
		}

		// Update ride status
		_, err = p.conn.Exec(ctx,
			`UPDATE rides SET status = $1 WHERE id = $2`,
			ride_status, proposal.RideID)
		if err != nil {
			return nil, err
		}
	}

	return &updatedProposal, nil
}

func (p *postgresRidesRepository) GetRideByID(ctx context.Context, rideID int64) (*domain.RideDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`SELECT id, status, created_at, updated_at FROM rides WHERE id = $1`,
		rideID)

	var ride domain.RideDBModel
	err := row.Scan(&ride.ID, &ride.Status, &ride.CreatedAt, &ride.UpdatedAt)
	if err != nil {
		return nil, err
	}

	return &ride, nil
}

func (p *postgresRidesRepository) GetProposalByID(ctx context.Context, proposalID int64) (*domain.ProposalDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`SELECT id, request_id, status, driver_id, ride_id, created_at, updated_at FROM proposals WHERE id = $1`,
		proposalID)

	var proposal domain.ProposalDBModel
	err := row.Scan(&proposal.ID, &proposal.RequestID, &proposal.Status, &proposal.DriverID, &proposal.RideID, &proposal.CreatedAt, &proposal.UpdatedAt)
	if err != nil {
		return nil, err
	}

	return &proposal, nil
}

func (p *postgresRidesRepository) GetRequestByID(ctx context.Context, requestID int64) (*domain.RequestDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`SELECT id, pickup_location, dropoff_location, compensation, passenger_id, ride_id, created_at FROM requests WHERE id = $1`,
		requestID)

	var request domain.RequestDBModel
	err := row.Scan(&request.ID, &request.PickupLocation, &request.DropoffLocation, &request.Compensation, &request.PassengerID, &request.RideID, &request.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &request, nil
}

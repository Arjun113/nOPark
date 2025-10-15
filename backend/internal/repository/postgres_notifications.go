package repository

import (
	"context"

	"github.com/Arjun113/nOPark/internal/domain"
)

type postgresNotificationsRepository struct {
	conn Connection
}

func NewPostgresNotifications(conn Connection) domain.NotificationsRepository {
	return &postgresNotificationsRepository{conn: conn}
}

func (p *postgresNotificationsRepository) CreateNotification(ctx context.Context, notification *domain.NotificationDBModel) (*domain.NotificationDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`INSERT INTO notifications (notification_type, notification_message, payload, account_id, is_sent) 
		 VALUES ($1, $2, $3, $4, $5) 
		 RETURNING id, notification_type, notification_message, payload, account_id, is_sent, created_at`,
		notification.NotificationType, notification.NotificationMessage, notification.Payload, notification.AccountID, false)

	var n domain.NotificationDBModel
	err := row.Scan(&n.ID, &n.NotificationType, &n.NotificationMessage, &n.Payload, &n.AccountID, &n.IsSent, &n.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &n, nil
}

func (p *postgresNotificationsRepository) GetNotificationsByAccountID(ctx context.Context, accountID int64) ([]*domain.NotificationDBModel, error) {
	rows, err := p.conn.Query(ctx,
		`SELECT id, notification_type, notification_message, payload, account_id, is_sent, created_at 
		 FROM notifications 
		 WHERE account_id = $1 
		 ORDER BY created_at DESC`,
		accountID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var notifications []*domain.NotificationDBModel
	for rows.Next() {
		var n domain.NotificationDBModel
		if err := rows.Scan(&n.ID, &n.NotificationType, &n.NotificationMessage, &n.Payload, &n.AccountID, &n.IsSent, &n.CreatedAt); err != nil {
			return nil, err
		}
		notifications = append(notifications, &n)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return notifications, nil
}

func (p *postgresNotificationsRepository) GetUnnotifiedRideRequests(ctx context.Context) ([]*domain.RequestDBModel, error) {
	rows, err := p.conn.Query(ctx,
		`SELECT id, pickup_location, dropoff_location, compensation, passenger_id, notifs_crtd, created_at 
		 FROM requests 
		 WHERE ride_id IS NULL AND notifs_crtd = FALSE
		 ORDER BY created_at DESC`)
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

func (p *postgresNotificationsRepository) MarkNotificationAsSent(ctx context.Context, notificationID int64) error {
	_, err := p.conn.Exec(ctx, "UPDATE notifications SET is_sent = true WHERE id = $1", notificationID)
	return err
}

func (p *postgresNotificationsRepository) MarkRequestNotificationsCreated(ctx context.Context, requestID int64) error {
	_, err := p.conn.Exec(ctx, "UPDATE requests SET notifs_crtd = true WHERE id = $1", requestID)
	return err
}

func (p *postgresNotificationsRepository) GetPendingNotifications(ctx context.Context, limit int) ([]*domain.NotificationWithAccountDBModel, error) {
	rows, err := p.conn.Query(ctx,
		`SELECT n.id, n.notification_type, n.notification_message, n.payload, n.account_id, n.is_sent, n.created_at,
		        a.email, a.firstname, a.lastname, a.fcm_token
		 FROM notifications n
		 JOIN accounts a ON n.account_id = a.id
		 WHERE n.is_sent = false
		 ORDER BY n.created_at ASC
		 LIMIT $1`,
		limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var notifications []*domain.NotificationWithAccountDBModel
	for rows.Next() {
		var n domain.NotificationWithAccountDBModel
		if err := rows.Scan(&n.ID, &n.NotificationType, &n.NotificationMessage, &n.Payload, &n.AccountID, &n.Sent, &n.CreatedAt,
			&n.AccountEmail, &n.AccountFirstName, &n.AccountLastName, &n.AccountFCMToken); err != nil {
			return nil, err
		}
		notifications = append(notifications, &n)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return notifications, nil
}

func (p *postgresNotificationsRepository) ProximityNotificationExists(ctx context.Context, passengerID, driverID, rideID int64) (bool, error) {
	var exists bool
	err := p.conn.QueryRow(ctx,
		`SELECT EXISTS(
			SELECT 1 FROM notifications 
			WHERE notification_type = 'proximity' 
			AND account_id = $1 
			AND notification_message LIKE '%Driver ' || $2 || ' for ride ' || $3 || '%'
		)`,
		passengerID, driverID, rideID).Scan(&exists)
	if err != nil {
		return false, err
	}
	return exists, nil
}

package domain

import (
	"context"
	"time"
)

type NotificationsRepository interface {
	CreateNotification(ctx context.Context, notification *NotificationDBModel) (*NotificationDBModel, error)
	GetNotificationsByAccountID(ctx context.Context, accountID int64) ([]*NotificationDBModel, error)
	GetUnnotifiedRideRequests(ctx context.Context) ([]*RequestDBModel, error)
	GetPendingNotifications(ctx context.Context, limit int) ([]*NotificationWithAccountDBModel, error)
	MarkNotificationAsSent(ctx context.Context, notificationID int64) error
	MarkRequestNotificationsCreated(ctx context.Context, requestID int64) error
}

type NotificationDBModel struct {
	ID                  int64
	NotificationType    string
	NotificationMessage string
	Payload             *string
	AccountID           int64
	IsSent              bool
	CreatedAt           string
}

type NotificationWithAccountDBModel struct {
	ID                  int64
	NotificationType    string
	NotificationMessage string
	Payload             *string
	AccountID           int64
	Sent                bool
	CreatedAt           string
	AccountEmail        string
	AccountFirstName    string
	AccountLastName     string
	AccountFCMToken     string
}

// For payload to distinguish different notifications in Ride Update channel
const (
	NotificationRequestCreated = "request_created"
	NotificationRideCreated    = "ride_created"
	NotificationRideFinalized  = "ride_finalized"
	NotificationRideCompleted  = "ride_completed"
)

// For channel IDs in FCM messages
const (
	NotificationTypeRideUpdates = "ride_updates"
	NotificationTypeProximity   = "proximity"
	NotificationTypeReview      = "review"
)

const NotificationCheckInterval = 5 * time.Second

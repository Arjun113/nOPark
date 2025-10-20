package services

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"go.uber.org/zap"
	"google.golang.org/api/option"

	"github.com/Arjun113/nOPark/internal/domain"
)

type FCMService struct {
	client *messaging.Client
	logger *zap.Logger
}

func NewFCMService(ctx context.Context, logger *zap.Logger) (*FCMService, error) {
	credentialsPath := os.Getenv("FIREBASE_CREDENTIALS_PATH")
	if credentialsPath == "" {
		return nil, fmt.Errorf("FIREBASE_CREDENTIALS_PATH environment variable not set")
	}

	config := &firebase.Config{
		ProjectID: "nopark-3162",
	}

	opt := option.WithCredentialsFile(credentialsPath)
	app, err := firebase.NewApp(ctx, config, opt)
	if err != nil {
		return nil, fmt.Errorf("error initialising Firebase SDK: %w", err)
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("error getting Messaging client: %w", err)
	}

	return &FCMService{
		client: client,
		logger: logger,
	}, nil
}

func (f *FCMService) SendNotification(ctx context.Context, notification *domain.NotificationWithAccountDBModel) error {
	fcmToken := notification.AccountFCMToken

	message := f.createMessageFromNotification(notification, fcmToken)

	msgJSON, err := json.MarshalIndent(message, "", "  ")
	if err != nil {
		payloadStr := ""
		if notification.Payload != nil {
			payloadStr = *notification.Payload
		}
		f.logger.Warn("Failed to marshal entire FCM message for logging",
			zap.Error(err),
			zap.Int64("notification_id", notification.ID),
			zap.String("recipient", notification.AccountEmail),
			zap.String("payload", payloadStr))
	} else {
		f.logger.Info("FCM message full dump",
			zap.Int64("notification_id", notification.ID),
			zap.String("recipient", notification.AccountEmail),
			zap.String("full_message_json", string(msgJSON)))
	}

	response, err := f.client.Send(ctx, message)
	if err != nil {
		f.logger.Error("Failed to send FCM notification",
			zap.Error(err),
			zap.Int64("notification_id", notification.ID),
			zap.String("recipient", notification.AccountEmail))
		return fmt.Errorf("failed to send FCM notification: %w", err)
	}

	f.logger.Info("📱 FCM notification sent successfully",
		zap.String("message_id", response),
		zap.Int64("notification_id", notification.ID),
		zap.String("recipient", notification.AccountEmail),
		zap.String("type", notification.NotificationType))

	return nil
}

func (f *FCMService) createMessageFromNotification(notification *domain.NotificationWithAccountDBModel, fcmToken string) *messaging.Message {
	// Start with base data fields
	data := map[string]string{
		"notification_id":   fmt.Sprintf("%d", notification.ID),
		"notification_type": notification.NotificationType,
		"user_name":         fmt.Sprintf("%s %s", notification.AccountFirstName, notification.AccountLastName),
		"created_at":        notification.CreatedAt,
	}

	// If payload exists, deserialize and merge it with base data
	if notification.Payload != nil && *notification.Payload != "" {
		var payloadData map[string]any
		if err := json.Unmarshal([]byte(*notification.Payload), &payloadData); err != nil {
			f.logger.Error("Failed to unmarshal notification payload",
				zap.Error(err),
				zap.Int64("notification_id", notification.ID),
				zap.String("payload", *notification.Payload))
		} else {
			// Merge payload data into the data map (converts all values to strings)
			for key, value := range payloadData {
				data[key] = fmt.Sprintf("%v", value)
			}
		}
	}

	return &messaging.Message{
		Token: fcmToken,
		Notification: &messaging.Notification{
			Title: f.getNotificationTitle(notification.NotificationType),
			Body:  notification.NotificationMessage,
		},
		Data:    data,
		Android: f.getAndroidConfig(notification.NotificationType),
	}
}

func (f *FCMService) getNotificationTitle(notificationType string) string {
	switch notificationType {
	case domain.NotificationTypeRideUpdates:
		return "🚗 nOPark - Ride Update"
	case domain.NotificationTypeProximity:
		return "📍 nOPark - Location Alert"
	case domain.NotificationTypeReview:
		return "⭐ nOPark - Review Received"
	default:
		return "🔔 nOPark Notification"
	}
}

func (f *FCMService) getAndroidConfig(notificationType string) *messaging.AndroidConfig {
	return &messaging.AndroidConfig{
		Priority: "high",
		Notification: &messaging.AndroidNotification{
			Icon:      "ic_notification",
			Color:     "#4285F4",
			Sound:     "default",
			ChannelID: f.getChannelID(notificationType),
		},
	}
}

func (f *FCMService) getChannelID(notificationType string) string {
	switch notificationType {
	case domain.NotificationTypeRideUpdates:
		return "ride_updates"
	case domain.NotificationTypeProximity:
		return "location_alerts"
	case domain.NotificationTypeReview:
		return "reviews"
	default:
		return "general"
	}
}

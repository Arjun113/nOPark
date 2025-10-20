package services

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"go.uber.org/zap"
	"google.golang.org/api/option"

	"github.com/Arjun113/nOPark/internal/domain"
)

type FCMService struct {
	client *messaging.Client
	logger *zap.Logger
	// serialize sends to avoid client-internal races under high concurrency
	sendMu sync.Mutex
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

	if notification.Payload == nil {
		f.logger.Info("Notification db model has no payload", zap.Int64("notification_id", notification.ID))
	}

	if strings.TrimSpace(fcmToken) == "" {
		f.logger.Error("empty FCM token; cannot send", zap.Int64("notification_id", notification.ID), zap.String("recipient", notification.AccountEmail))
		return fmt.Errorf("empty fcm token for notification %d", notification.ID)
	}

	message := f.createMessageFromNotification(notification, fcmToken)

	// Log a token preview and data keys for debugging (do not log full token)
	tokenPreview := fcmToken
	if len(tokenPreview) > 8 {
		tokenPreview = tokenPreview[:8] + "..."
	}
	f.logger.Info("sending fcm notification", zap.Int64("notification_id", notification.ID), zap.String("token_preview", tokenPreview), zap.Any("data_keys", keysOfMap(message.Data)))

	// Serialize sends to avoid client races and rate spikes
	f.sendMu.Lock()
	defer f.sendMu.Unlock()

	var lastErr error
	var resp string
	maxAttempts := 3
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		resp, lastErr = f.client.Send(ctx, message)
		if lastErr == nil {
			f.logger.Info("📱 FCM notification sent successfully", zap.String("message_id", resp), zap.Int64("notification_id", notification.ID), zap.String("recipient", notification.AccountEmail), zap.String("type", notification.NotificationType))
			return nil
		}

		// Log and backoff then retry
		f.logger.Warn("send attempt failed; will retry if attempts remain", zap.Int("attempt", attempt), zap.Int64("notification_id", notification.ID), zap.Error(lastErr))
		time.Sleep(time.Duration(attempt*200) * time.Millisecond)
	}

	f.logger.Error("failed to send notification after retries", zap.Int64("notification_id", notification.ID), zap.Error(lastErr))
	return fmt.Errorf("failed to send FCM notification after %d attempts: %w", maxAttempts, lastErr)
}

func (f *FCMService) createMessageFromNotification(
	origNotification *domain.NotificationWithAccountDBModel,
	fcmToken string,
) *messaging.Message {
	notification := *origNotification // copy to avoid pointer races

	// Base data fields (never overridden)
	data := map[string]string{
		"notification_id":   fmt.Sprintf("%d", notification.ID),
		"notification_type": notification.NotificationType,
		"user_name":         fmt.Sprintf("%s %s", notification.AccountFirstName, notification.AccountLastName),
		"created_at":        notification.CreatedAt,
	}

	// Merge payload safely into data (without touching NotificationType or core fields)
	if notification.Payload != nil && *notification.Payload != "" {
		var payloadData map[string]any
		if err := json.Unmarshal([]byte(*notification.Payload), &payloadData); err != nil {
			f.logger.Error("Failed to unmarshal payload",
				zap.Error(err),
				zap.Int64("notification_id", notification.ID),
				zap.String("payload", *notification.Payload))
		} else {
			for key, value := range payloadData {
				if key == "notification_id" || key == "notification_type" || key == "user_name" || key == "created_at" {
					continue
				}
				data[key] = fmt.Sprintf("%v", value)
			}
		}
	}

	// Build message
	message := &messaging.Message{
		Token: fcmToken,
		Notification: &messaging.Notification{
			Title: f.getNotificationTitle(notification.NotificationType),
			Body:  notification.NotificationMessage,
		},
		Data:    data,
		Android: f.getAndroidConfig(notification.NotificationType),
	}
	f.logger.Debug("FCM message created", zap.Any("message_struct", message))
	return message
}

// keysOfMap returns the keys of a map as []string
func keysOfMap(m map[string]string) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	return out
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

package cmd

import (
	"context"
	"fmt"
	"time"

	"github.com/go-co-op/gocron"
	"github.com/spf13/cobra"
	"go.uber.org/zap"

	"github.com/Arjun113/nOPark/internal/cmdutil"
	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/Arjun113/nOPark/internal/repository"
	"github.com/Arjun113/nOPark/internal/services"
)

func WorkerCmd(ctx context.Context) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "worker",
		Args:  cobra.ExactArgs(0),
		Short: "Handles notification scheduling and processing.",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := cmdutil.NewLogger("worker")
			defer func() { _ = logger.Sync() }()

			db, err := cmdutil.NewDatabasePool(ctx, 4)
			if err != nil {
				return fmt.Errorf("could not connect to database: %w", err)
			}
			defer db.Close()

			// Initialize repositories
			accountRepo := repository.NewPostgresAccounts(db)
			notificationRepo := repository.NewPostgresNotifications(db)
			ratelimitRepo := repository.NewPostgresRatelimit(db)

			// Initialize FCM service for notifications
			fcmService, err := services.NewFCMService(ctx, logger)
			if err != nil {
				logger.Error("failed to initialise FCM service", zap.Error(err))
				fcmService = nil
			} else {
				logger.Info("FCM service initialised successfully")
			}

			// Setup scheduler
			s := gocron.NewScheduler(time.UTC)
			s.SetMaxConcurrentJobs(4, gocron.WaitMode)

			// Schedule notification creation job every 5 seconds
			_, err = s.Every(5).Seconds().Do(func() {
				createNotificationsForNewRideRequests(ctx, logger, accountRepo, notificationRepo)
			})
			if err != nil {
				return fmt.Errorf("failed to schedule notification creation job: %w", err)
			}

			// Schedule cleanup of expired IP blocks every 5 minutes
			_, err = s.Every(5).Minutes().Do(func() {
				ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
				defer cancel()
				count, err := ratelimitRepo.CleanupExpiredBlocks(ctx)
				if err != nil {
					logger.Error("Failed to clean up expired IP blocks", zap.Error(err))
				} else if count > 0 {
					logger.Info("Cleaned up expired IP blocks", zap.Int("count", count))
				}
			})
			if err != nil {
				return fmt.Errorf("failed to schedule IP block cleanup job: %w", err)
			}

			// Schedule notification processing job every 3 seconds
			_, err = s.Every(3).Seconds().Do(func() {
				err := processNotifications(ctx, logger, notificationRepo, fcmService)
				if err != nil {
					logger.Error("error processing notifications", zap.Error(err))
				}
			})
			if err != nil {
				return fmt.Errorf("failed to schedule notification processing job: %w", err)
			}

			logger.Info("combined worker started - scheduling notifications every 5s, processing every 3s, cleanup every 5min")
			s.StartBlocking()

			return nil
		},
	}

	return cmd
}

func createNotificationsForNewRideRequests(ctx context.Context, logger *zap.Logger, accountRepo domain.AccountsRepository, notificationRepo domain.NotificationsRepository) {
	logger.Debug("checking for new ride requests without notifications")

	newRequests, err := notificationRepo.GetUnnotifiedRideRequests(ctx)
	if err != nil {
		logger.Error("failed to fetch new ride requests", zap.Error(err))
		return
	}

	if len(newRequests) == 0 {
		logger.Debug("no new ride requests found")
		return
	}

	logger.Info("found new ride requests", zap.Int("count", len(newRequests)))

	drivers, err := accountRepo.GetAccountsByType(ctx, "driver")
	if err != nil {
		logger.Error("failed to fetch driver accounts", zap.Error(err))
		return
	}

	if len(drivers) == 0 {
		logger.Debug("no driver accounts found")
		return
	}

	logger.Info("creating notifications for drivers", zap.Int("driver_count", len(drivers)))

	notificationsCreated := 0
	for _, request := range newRequests {
		requestNotificationsCreated := 0
		for _, driver := range drivers {
			notification := &domain.NotificationDBModel{
				NotificationType:    domain.NotificationTypeRideRequest,
				NotificationMessage: fmt.Sprintf("New ride request: %s to %s (Compensation: $%.2f)", request.PickupLocation, request.DropoffLocation, request.Compensation),
				AccountID:           driver.ID,
			}

			createdNotification, err := notificationRepo.CreateNotification(ctx, notification)
			if err != nil {
				logger.Error("failed to create notification",
					zap.Error(err),
					zap.Int64("driver_id", driver.ID),
					zap.Int64("request_id", request.ID))
				continue
			}

			requestNotificationsCreated++
			notificationsCreated++
			logger.Debug("notification created in database",
				zap.Int64("notification_id", createdNotification.ID),
				zap.Int64("driver_id", driver.ID),
				zap.Int64("request_id", request.ID))
		}

		// Mark the request as having notifications created if at least one notification was successfully created
		if requestNotificationsCreated > 0 {
			err := notificationRepo.MarkRequestNotificationsCreated(ctx, request.ID)
			if err != nil {
				logger.Error("failed to mark request notifications as created",
					zap.Error(err),
					zap.Int64("request_id", request.ID))
			} else {
				logger.Debug("request marked as having notifications created",
					zap.Int64("request_id", request.ID),
					zap.Int("notifications_created_for_request", requestNotificationsCreated))
			}
		}
	}

	logger.Info("notifications created",
		zap.Int("total_created", notificationsCreated),
		zap.Int("requests_processed", len(newRequests)))
}

func processNotifications(ctx context.Context, logger *zap.Logger, notificationRepo domain.NotificationsRepository, fcmService *services.FCMService) error {
	pendingNotifications, err := notificationRepo.GetPendingNotifications(ctx, 20)
	if err != nil {
		return fmt.Errorf("failed to fetch pending notifications: %w", err)
	}

	if len(pendingNotifications) == 0 {
		logger.Debug("no pending notifications to process")
		return nil
	}

	logger.Info("processing notifications", zap.Int("count", len(pendingNotifications)))

	successCount := 0
	failureCount := 0

	for _, notification := range pendingNotifications {
		if fcmService == nil {
			logger.Warn("FCM service not available, skipping notification",
				zap.Int64("notification_id", notification.ID))
			failureCount++
			continue
		}

		err := fcmService.SendNotification(ctx, notification)
		if err != nil {
			logger.Error("failed to send notification",
				zap.Error(err),
				zap.Int64("notification_id", notification.ID),
				zap.String("recipient_account_email", notification.AccountEmail),
				zap.String("fcm_token", notification.AccountFCMToken),
			)

			failureCount++
			continue
		}

		err = notificationRepo.MarkNotificationAsSent(ctx, notification.ID)
		if err != nil {
			logger.Error("failed to mark notification as sent",
				zap.Error(err),
				zap.Int64("notification_id", notification.ID))
			failureCount++
			continue
		}

		successCount++
	}

	logger.Info("notification processing completed",
		zap.Int("success_count", successCount),
		zap.Int("failure_count", failureCount))

	return nil
}

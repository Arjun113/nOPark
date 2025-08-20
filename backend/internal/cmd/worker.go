package cmd

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/spf13/cobra"
	"go.uber.org/zap"

	"github.com/Arjun113/nOPark/internal/cmdutil"
	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/Arjun113/nOPark/internal/repository"
	"github.com/Arjun113/nOPark/internal/services"
)

func WorkerCmd(ctx context.Context) *cobra.Command {
	var workerType string

	cmd := &cobra.Command{
		Use:   "worker",
		Args:  cobra.ExactArgs(0),
		Short: "Process notification jobs and other background tasks.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if workerType == "" {
				return fmt.Errorf("need a worker type to work on")
			}

			svc := fmt.Sprintf("worker: %s", workerType)
			logger := cmdutil.NewLogger(svc)
			defer func() { _ = logger.Sync() }()

			db, err := cmdutil.NewDatabasePool(ctx, 2)
			if err != nil {
				return err
			}
			defer db.Close()

			switch workerType {
			case "notifications":
				return runNotificationWorker(ctx, logger, db)
			default:
				return fmt.Errorf("invalid worker type: %s", workerType)
			}
		},
	}

	cmd.Flags().StringVar(&workerType, "type", "", "The type of worker to run (notifications)")

	return cmd
}

func runNotificationWorker(ctx context.Context, logger *zap.Logger, db *pgxpool.Pool) error {
	logger.Info("starting notification worker")

	notificationRepo := repository.NewPostgresNotifications(db)

	fcmService, err := services.NewFCMService(ctx, logger)
	if err != nil {
		logger.Error("failed to initialise FCM service", zap.Error(err))
		fcmService = nil
	} else {
		logger.Info("FCM service initialised successfully")
	}

	ticker := time.NewTicker(3 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			logger.Info("notification worker stopped")
			return nil
		case <-ticker.C:
			err := processNotifications(ctx, logger, notificationRepo, fcmService)
			if err != nil {
				logger.Error("error processing notifications", zap.Error(err))
			}
		}
	}
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

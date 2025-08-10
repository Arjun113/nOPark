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
)

func SchedulerCmd(ctx context.Context) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "scheduler",
		Args:  cobra.ExactArgs(0),
		Short: "Schedules jobs and runs notification tasks periodically.",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := cmdutil.NewLogger("scheduler")
			defer func() { _ = logger.Sync() }()

			db, err := cmdutil.NewDatabasePool(ctx, 4)
			if err != nil {
				return fmt.Errorf("could not connect to database: %w", err)
			}
			defer db.Close()

			accountRepo := repository.NewPostgresAccounts(db)
			notificationRepo := repository.NewPostgresNotifications(db)

			s := gocron.NewScheduler(time.UTC)
			s.SetMaxConcurrentJobs(2, gocron.WaitMode)

			_, err = s.Every(5).Seconds().Do(func() {
				createNotificationsForNewRideRequests(ctx, logger, accountRepo, notificationRepo)
			})
			if err != nil {
				return fmt.Errorf("failed to schedule notification job: %w", err)
			}

			logger.Info("scheduler started - checking for new ride requests every 5 seconds")
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

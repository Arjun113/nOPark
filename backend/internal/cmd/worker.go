package cmd

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/go-co-op/gocron"
	"github.com/spf13/cobra"
	"go.uber.org/zap"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/Arjun113/nOPark/internal/repository"
	"github.com/Arjun113/nOPark/internal/services"
	"github.com/Arjun113/nOPark/internal/utils"
)

func WorkerCmd(ctx context.Context) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "worker",
		Args:  cobra.ExactArgs(0),
		Short: "Handles notification scheduling and processing.",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := utils.NewLogger("worker")
			defer func() { _ = logger.Sync() }()

			db, err := utils.NewDatabasePool(ctx, 4)
			if err != nil {
				return fmt.Errorf("could not connect to database: %w", err)
			}
			defer db.Close()

			accountRepo := repository.NewPostgresAccounts(db)
			notificationRepo := repository.NewPostgresNotifications(db)
			ratelimitRepo := repository.NewPostgresRatelimit(db)
			ridesRepo := repository.NewPostgresRides(db)
			fcmService, err := services.NewFCMService(ctx, logger)
			if err != nil {
				logger.Error("failed to initialise FCM service", zap.Error(err))
				fcmService = nil
			} else {
				logger.Info("FCM service initialised successfully")
			}

			// Setup scheduler
			s := gocron.NewScheduler(time.UTC)
			s.SetMaxConcurrentJobs(4, gocron.RescheduleMode)

			// Schedule notification creation job every 5 seconds
			_, err = s.Every(5).Seconds().Do(func() {
				createNotificationsForNewRideRequests(ctx, logger, accountRepo, notificationRepo)
			})
			if err != nil {
				return fmt.Errorf("failed to schedule notification creation job: %w", err)
			}

			// Schedule proximity notification creation job every 5 seconds
			_, err = s.Every(5).Seconds().Do(func() {
				createNotificationsForDriverCloseToPassenger(ctx, logger, ridesRepo, notificationRepo)
			})
			if err != nil {
				return fmt.Errorf("failed to schedule proximity notification creation job: %w", err)
			} // Schedule cleanup of unverified expired accounts every hour
			_, err = s.Every(2).Minutes().Do(func() {
				ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				defer cancel()
				count, err := accountRepo.RemoveUnverifiedExpiredAccounts(ctx)
				if err != nil {
					logger.Error("failed to remove unverified expired accounts", zap.Error(err))
				} else {
					logger.Info("Cleaned up unverified expired accounts", zap.Int("count", int(count)))
				}
			})
			if err != nil {
				return fmt.Errorf("failed to schedule unverified expired accounts cleanup job: %w", err)
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
			var processingMutex sync.Mutex
			_, err = s.Every(3).Seconds().Do(func() {
				if !processingMutex.TryLock() {
					logger.Warn("previous notification processing still running, skipping this run")
					return
				}
				defer processingMutex.Unlock()

				// extend timeout so SendNotification retry/backoff has time to complete
				local_ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				defer cancel()

				err := processNotifications(local_ctx, logger, notificationRepo, fcmService)
				if err != nil {
					logger.Error("error processing notifications", zap.Error(err))
				}
			})
			if err != nil {
				return fmt.Errorf("failed to schedule notification processing job: %w", err)
			}

			logger.Info("combined worker started - scheduling notifications every 5s, proximity checks every 5s, processing every 3s, cleanup every 5min")
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
			notificationPayload := fmt.Sprintf(`{"notification": "%s"}`, domain.NotificationRequestCreated)
			notification := &domain.NotificationDBModel{
				NotificationType:    domain.NotificationTypeRideUpdates,
				NotificationMessage: fmt.Sprintf("New ride request: %s to %s (Compensation: $%.2f)", request.PickupLocation, request.DropoffLocation, request.Compensation),
				AccountID:           driver.ID,
				Payload:             &notificationPayload,
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
	// fetch smaller batches to avoid bursts and allow sequential sending
	pendingNotifications, err := notificationRepo.GetPendingNotifications(ctx, 5)
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

		// small pause between sends to avoid rate spikes
		time.Sleep(150 * time.Millisecond)

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

func createNotificationsForDriverCloseToPassenger(ctx context.Context, logger *zap.Logger, ridesRepo domain.RidesRepository, notificationRepo domain.NotificationsRepository) {
	logger.Debug("checking for drivers close to passengers")

	// Get all in-progress rides with driver and passenger locations
	ridesWithLocations, err := ridesRepo.GetInProgressRidesWithLocations(ctx)
	if err != nil {
		logger.Error("failed to fetch in-progress rides with locations", zap.Error(err))
		return
	}

	if len(ridesWithLocations) == 0 {
		logger.Debug("no in-progress rides found")
		return
	}

	logger.Debug("found in-progress rides", zap.Int("count", len(ridesWithLocations)))

	notificationsCreated := 0

	for _, ride := range ridesWithLocations {
		// Check if both driver and passenger have locations
		if ride.DriverLatitude == nil || ride.DriverLongitude == nil {
			logger.Debug("driver location not available",
				zap.Int64("ride_id", ride.RideID),
				zap.Int64("driver_id", ride.DriverID))
			continue
		}

		if ride.PassengerLatitude == nil || ride.PassengerLongitude == nil {
			logger.Debug("passenger location not available",
				zap.Int64("ride_id", ride.RideID),
				zap.Int64("passenger_id", ride.PassengerID))
			continue
		}

		// Calculate distance between driver and passenger (pickup location)
		distanceKm := domain.CalculateHaversineDistance(
			*ride.DriverLatitude,
			*ride.DriverLongitude,
			ride.PickupLatitude,
			ride.PickupLongitude,
		)

		// Check if driver is within 100 meters (0.1 km) of the pickup location
		if distanceKm > 0.1 {
			logger.Debug("driver not close enough to pickup location",
				zap.Int64("ride_id", ride.RideID),
				zap.Int64("driver_id", ride.DriverID),
				zap.Int64("passenger_id", ride.PassengerID),
				zap.Float64("distance_km", distanceKm))
			continue
		}

		// Check if we've already sent a proximity notification for this driver-passenger-ride combo
		exists, err := notificationRepo.ProximityNotificationExists(ctx, ride.PassengerID, ride.DriverID, ride.RideID)
		if err != nil {
			logger.Error("failed to check for existing proximity notification",
				zap.Error(err),
				zap.Int64("ride_id", ride.RideID),
				zap.Int64("driver_id", ride.DriverID),
				zap.Int64("passenger_id", ride.PassengerID))
			continue
		}

		if exists {
			logger.Debug("proximity notification already exists",
				zap.Int64("ride_id", ride.RideID),
				zap.Int64("driver_id", ride.DriverID),
				zap.Int64("passenger_id", ride.PassengerID))
			continue
		}

		// Create the proximity notification
		notification := &domain.NotificationDBModel{
			NotificationType:    domain.NotificationTypeProximity,
			NotificationMessage: fmt.Sprintf("Driver %d for ride %d is nearby! They are approximately %.0f meters away.", ride.DriverID, ride.RideID, distanceKm*1000),
			AccountID:           ride.PassengerID,
		}

		createdNotification, err := notificationRepo.CreateNotification(ctx, notification)
		if err != nil {
			logger.Error("failed to create proximity notification",
				zap.Error(err),
				zap.Int64("ride_id", ride.RideID),
				zap.Int64("driver_id", ride.DriverID),
				zap.Int64("passenger_id", ride.PassengerID))
			continue
		}

		notificationsCreated++
		logger.Info("proximity notification created",
			zap.Int64("notification_id", createdNotification.ID),
			zap.Int64("ride_id", ride.RideID),
			zap.Int64("driver_id", ride.DriverID),
			zap.Int64("passenger_id", ride.PassengerID),
			zap.Float64("distance_meters", distanceKm*1000))
	}

	if notificationsCreated > 0 {
		logger.Info("proximity notifications created",
			zap.Int("total_created", notificationsCreated))
	}
}

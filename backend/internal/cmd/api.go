package cmd

import (
	"context"
	"os"
	"strconv"

	"github.com/Arjun113/nOPark/internal/api"
	"github.com/Arjun113/nOPark/internal/utils"
	"github.com/spf13/cobra"
	"go.uber.org/zap"
)

func APICmd(ctx context.Context) *cobra.Command {
	var port int

	cmd := &cobra.Command{
		Use:   "api",
		Args:  cobra.ExactArgs(0),
		Short: "Runs the RESTful API.",
		RunE: func(cmd *cobra.Command, args []string) error {
			port = 4000
			if os.Getenv("PORT") != "" {
				port, _ = strconv.Atoi(os.Getenv("PORT"))
			}

			logger := utils.NewLogger("api")
			defer func() { _ = logger.Sync() }()

			db, err := utils.NewDatabasePool(ctx, 16)
			if err != nil {
				return err
			}
			defer db.Close()

			api := api.NewAPI(ctx, logger, db)
			srv := api.Server(port)

			errChan := make(chan error, 1)
			go func() {
				if err := srv.ListenAndServe(); err != nil {
					errChan <- err
				}
			}()

			logger.Info("started api", zap.Int("port", port))

			select {
			case err := <-errChan:
				logger.Error("failed to start server", zap.Error(err), zap.Int("port", port))
				return err
			case <-ctx.Done():
				_ = srv.Shutdown(ctx)
				return nil
			}
		},
	}

	return cmd
}

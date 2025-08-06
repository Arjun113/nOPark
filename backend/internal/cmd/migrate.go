package cmd

import (
	"context"
	"database/sql"
	"fmt"
	"os"

	"github.com/Arjun113/nOPark/internal/cmdutil"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/pgx/v5"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/spf13/cobra"
	"go.uber.org/zap"
)

func MigrateCmd(ctx context.Context) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "migrate",
		Short: "Database migration commands",
	}

	cmd.AddCommand(migrateUpCmd(ctx))
	cmd.AddCommand(migrateDownCmd(ctx))
	cmd.AddCommand(migrateStatusCmd(ctx))
	cmd.AddCommand(migrateVersionCmd(ctx))

	return cmd
}

func migrateUpCmd(ctx context.Context) *cobra.Command {
	return &cobra.Command{
		Use:   "up",
		Short: "Apply all pending migrations",
		RunE: func(cmd *cobra.Command, args []string) error {
			m, err := newMigrate(ctx)
			if err != nil {
				return err
			}
			defer m.Close()

			logger := cmdutil.NewLogger("migrate")
			defer func() { _ = logger.Sync() }()

			if err := m.Up(); err != nil && err != migrate.ErrNoChange {
				logger.Error("migration failed", zap.Error(err))
				return err
			}

			logger.Info("migrations applied successfully")
			return nil
		},
	}
}

func migrateDownCmd(ctx context.Context) *cobra.Command {
	return &cobra.Command{
		Use:   "down",
		Short: "Rollback the last migration",
		RunE: func(cmd *cobra.Command, args []string) error {
			m, err := newMigrate(ctx)
			if err != nil {
				return err
			}
			defer m.Close()

			logger := cmdutil.NewLogger("migrate")
			defer func() { _ = logger.Sync() }()

			if err := m.Steps(-1); err != nil && err != migrate.ErrNoChange {
				logger.Error("migration rollback failed", zap.Error(err))
				return err
			}

			logger.Info("migration rolled back successfully")
			return nil
		},
	}
}

func migrateStatusCmd(ctx context.Context) *cobra.Command {
	return &cobra.Command{
		Use:   "status",
		Short: "Show current migration status",
		RunE: func(cmd *cobra.Command, args []string) error {
			m, err := newMigrate(ctx)
			if err != nil {
				return err
			}
			defer m.Close()

			version, dirty, err := m.Version()
			if err != nil {
				if err == migrate.ErrNilVersion {
					fmt.Println("No migrations have been applied yet")
					return nil
				}
				return err
			}

			status := "clean"
			if dirty {
				status = "dirty"
			}

			fmt.Printf("Current migration version: %d\n", version)
			fmt.Printf("Migration status: %s\n", status)
			return nil
		},
	}
}

func migrateVersionCmd(ctx context.Context) *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Show current migration version",
		RunE: func(cmd *cobra.Command, args []string) error {
			m, err := newMigrate(ctx)
			if err != nil {
				return err
			}
			defer m.Close()

			version, dirty, err := m.Version()
			if err != nil {
				if err == migrate.ErrNilVersion {
					fmt.Println("No migrations have been applied yet")
					return nil
				}
				return err
			}

			fmt.Printf("%d", version)
			if dirty {
				fmt.Print(" (dirty)")
			}
			fmt.Println()
			return nil
		},
	}
}

func newMigrate(ctx context.Context) (*migrate.Migrate, error) {
	// Get database URL from environment
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL environment variable is required")
	}

	// Open database connection using pgx driver with context
	db, err := sql.Open("pgx", databaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %w", err)
	}

	// Test the connection with context
	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Create pgx driver instance
	driver, err := pgx.WithInstance(db, &pgx.Config{})
	if err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to create pgx driver instance: %w", err)
	}

	// Create migrate instance
	m, err := migrate.NewWithDatabaseInstance(
		"file://migrations",
		"postgres", driver)
	if err != nil {
		return nil, fmt.Errorf("failed to create migrate instance: %w", err)
	}

	return m, nil
}

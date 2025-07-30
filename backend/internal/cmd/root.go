package cmd

import (
	"context"
	_ "net/http/pprof"

	"github.com/joho/godotenv"
	"github.com/spf13/cobra"
)

func Execute(ctx context.Context) int {
	_ = godotenv.Load()

	rootCmd := &cobra.Command{
		Use:   "nOPark",
		Short: "nOPark is a ride-sharing platform for Monash University students.",
	}

	rootCmd.AddCommand(APICmd(ctx))

	if err := rootCmd.Execute(); err != nil {
		return 1
	}

	return 0
}
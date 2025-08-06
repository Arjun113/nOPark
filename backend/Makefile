.PHONY: help api build install clean dev migrate-up migrate-down migrate-status migrate-version

# Default target
help:
	@echo "Available commands:"
	@echo "  make api            - Run the API server"
	@echo "  make build          - Build the application"
	@echo "  make install        - Install the binary to GOPATH/bin"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make dev            - Run in development mode with auto-reload"
	@echo "  make migrate-up     - Apply all pending migrations"
	@echo "  make migrate-down   - Rollback the last migration"
	@echo "  make migrate-status - Show current migration status"
	@echo "  make migrate-version- Show current migration version"

# Run the API server
api:
	go run cmd/nOPark/main.go api

# Build the application
build:
	go build -o bin/nOPark cmd/nOPark/main.go

# Install the binary to GOPATH/bin (makes it available globally)
install:
	go install cmd/nOPark/main.go

# Clean build artifacts
clean:
	rm -rf bin/

# Migration commands
migrate-up:
	go run cmd/nOPark/main.go migrate up

migrate-down:
	go run cmd/nOPark/main.go migrate down

migrate-status:
	go run cmd/nOPark/main.go migrate status

migrate-version:
	go run cmd/nOPark/main.go migrate version

.PHONY: api scheduler worker build install clean migrate-up migrate-down migrate-status migrate-version

# Run the API server
api:
	go run cmd/nOPark/main.go api

# Run the scheduler
scheduler:
	go run cmd/nOPark/main.go scheduler

# Run the worker
worker:
	go run cmd/nOPark/main.go worker

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

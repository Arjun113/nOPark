package api

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"github.com/Arjun113/nOPark/internal/repository"
	"go.uber.org/zap"
)

// IPBlockRequest represents a request to block an IP
type IPBlockRequest struct {
	IPAddress     string `json:"ip_address" validate:"required"`
	Reason        string `json:"reason"`
	DurationHours int    `json:"duration_hours" validate:"omitempty,min=1,max=720"` // 1 hours to 30 days
}

// IPBlockResponse represents a response to an IP block request
type IPBlockResponse struct {
	Message   string    `json:"message"`
	ExpiresAt time.Time `json:"expires_at"`
}

// blockIPHandler blocks an IP address for a specified duration
func (a *api) blockIPHandler(w http.ResponseWriter, r *http.Request) {
	// Check if user is admin
	session, ok := repository.GetSessionFromContext(r.Context())
	if !ok {
		a.errorResponse(w, r, http.StatusUnauthorized, errors.New("authentication required"))
		return
	}

	// Get the user account to check if they're an admin
	account, err := a.accountsRepo.GetAccountByID(r.Context(), session.AccountID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Check if user is an admin
	if account.Type != "admin" {
		a.errorResponse(w, r, http.StatusForbidden, errors.New("admin access required"))
		return
	}

	// Parse request body
	var req IPBlockRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	// Validate request
	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	// Set a default duration if not specified
	if req.DurationHours == 0 {
		req.DurationHours = 24 // Default: 24 hours
	}

	// Block the IP
	duration := time.Duration(req.DurationHours) * time.Hour
	err = a.ratelimitRepo.BlockIP(r.Context(), req.IPAddress, req.Reason, duration)
	if err != nil {
		a.logger.Error("Failed to block IP", zap.Error(err))
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Log the action
	a.logger.Info("IP address blocked",
		zap.String("ip", req.IPAddress),
		zap.String("reason", req.Reason),
		zap.Int("hours", req.DurationHours),
		zap.String("admin", account.Email),
	)

	// Return success response
	expiresAt := time.Now().Add(duration)
	response := IPBlockResponse{
		Message:   "IP address has been blocked",
		ExpiresAt: expiresAt,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// unblockIPHandler removes an IP from the blocklist
func (a *api) unblockIPHandler(w http.ResponseWriter, r *http.Request) {
	// Check if user is admin
	session, ok := repository.GetSessionFromContext(r.Context())
	if !ok {
		a.errorResponse(w, r, http.StatusUnauthorized, errors.New("authentication required"))
		return
	}

	// Get the user account to check if they're an admin
	account, err := a.accountsRepo.GetAccountByID(r.Context(), session.AccountID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Check if user is an admin
	if account.Type != "admin" {
		a.errorResponse(w, r, http.StatusForbidden, errors.New("admin access required"))
		return
	}

	// Get the IP to unblock
	ip := r.URL.Query().Get("ip")
	if ip == "" {
		a.errorResponse(w, r, http.StatusBadRequest, errors.New("ip parameter is required"))
		return
	}

	// Unblock the IP
	err = a.ratelimitRepo.UnblockIP(r.Context(), ip)
	if err != nil {
		a.logger.Error("Failed to unblock IP", zap.Error(err))
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Log the action
	a.logger.Info("IP address unblocked",
		zap.String("ip", ip),
		zap.String("admin", account.Email),
	)

	// Return success response
	response := map[string]string{
		"message": "IP address has been unblocked",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

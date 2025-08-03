package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/mail"
	"strings"
	"time"

	"github.com/Arjun113/nOPark/internal/domain"
	"go.uber.org/zap"
)

type CreateUserRequest struct {
	Email      string `json:"email"`
	Password   string `json:"password"`
	FirstName  string `json:"first_name"`
	MiddleName string `json:"middle_name,omitempty"`
	LastName   string `json:"last_name"`
}

type CreateUserResponse struct {
	Email     string          `json:"email"`
	FirstName string          `json:"first_name"`
	MiddleName string         `json:"middle_name,omitempty"`
	LastName  string          `json:"last_name"`
	Token   string          `json:"token,omitempty"`
}

func (a *api) createUserHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	// Parse request body
	var req CreateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	// Validate required fields
	if strings.TrimSpace(req.Email) == "" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("email is required"))
		return
	}
	if _, err := mail.ParseAddress(req.Email); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid email format"))
		return
	}
	if strings.TrimSpace(req.Password) == "" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("password is required"))
		return
	}
	if len(req.Password) < 8 {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("password must be at least 8 characters long"))
		return
	}
	if strings.TrimSpace(req.FirstName) == "" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("first name is required"))
		return
	}
	if strings.TrimSpace(req.LastName) == "" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("last name is required"))
		return
	}

	// Check if user already exists
	existingAccount, err := a.accountsRepo.GetAccountByEmail(ctx, req.Email)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if existingAccount != nil {
		a.errorResponse(w, r, http.StatusConflict, fmt.Errorf("account with this email already exists"))
		return
	}

	// Hash password
	hashedPassword, err := domain.HashPassword(req.Password)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Create account
	account := &domain.AccountDBModel{
		Email:        req.Email,
		PasswordHash: hashedPassword,
		FirstName:    req.FirstName,
		MiddleName:   req.MiddleName,
		LastName:     req.LastName,
	}

	createdAccount, err := a.accountsRepo.CreateAccount(ctx, account)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Create session
	id, token, secretHash := domain.GenerateSession()
	_, err = a.accountsRepo.CreateSession(ctx, id, secretHash, createdAccount.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Return response
	response := CreateUserResponse{
		Email:     createdAccount.Email,
		FirstName: createdAccount.FirstName,
		MiddleName: createdAccount.MiddleName,
		LastName:  createdAccount.LastName,
		Token: token,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}


type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type LoginResponse struct {
	Email     string          `json:"email"`
	FirstName string          `json:"first_name"`
	MiddleName string         `json:"middle_name,omitempty"`
	LastName  string          `json:"last_name"`
	Token   string          `json:"token,omitempty"`
}

func (a *api) loginUserHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	// Parse request body
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	// Validate required fields
	if strings.TrimSpace(req.Email) == "" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("email is required"))
		return
	}
	if _, err := mail.ParseAddress(req.Email); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid email format"))
		return
	}
	if strings.TrimSpace(req.Password) == "" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("password is required"))
		return
	}

	// Get account by email
	account, err := a.accountsRepo.GetAccountByEmail(ctx, req.Email)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if account == nil {
		// Use generic error message to prevent email enumeration
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("incorrect email or password"))
		return
	}

	// Verify password
	if !domain.CheckPasswordHash(req.Password, account.PasswordHash) {
		// Use generic error message to prevent email enumeration
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("incorrect email or password"))
		return
	}

	// Create session
	id, token, secretHash := domain.GenerateSession()
	_, err = a.accountsRepo.CreateSession(ctx, id, secretHash, account.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	// Return response
	response := LoginResponse{
		Email:     account.Email,
		FirstName: account.FirstName,
		MiddleName: account.MiddleName,
		LastName:  account.LastName,
		Token: token,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func (a *api) logoutUserHandler(w http.ResponseWriter, r *http.Request) {
	var sessionToken string

	authHeader := r.Header.Get("Authorization")
	if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
		sessionToken = strings.TrimPrefix(authHeader, "Bearer ")
	} else {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("auth token is required"))
		return
	}

	// Validate and delete the session from database
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	session, err := a.accountsRepo.ValidateSessionToken(ctx, sessionToken)
	if err != nil {
		// Session validation failed
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	if session != nil {
		// Delete the session from database
		err = a.accountsRepo.DeleteSession(ctx, session.ID)
		if err != nil {
			a.errorResponse(w, r, http.StatusInternalServerError, err)
			return
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "logged out successfully"})
}

// getUserHandler is the HTTP handler for getting user account information
type GetUserResponse struct {
	Email     string          `json:"email"`
	FirstName string          `json:"first_name"`
	MiddleName string         `json:"middle_name,omitempty"`
	LastName  string          `json:"last_name"`
}
func (a *api) getUserHandler(w http.ResponseWriter, r *http.Request) {
	account, err := a.getCurrentUser(r)
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}

	response := GetUserResponse{
		Email:     account.Email,
		FirstName: account.FirstName,
		MiddleName: account.MiddleName,
		LastName:  account.LastName,
	}
	
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

type VerifyEmailRequest struct {
	Token string `json:"token"`
}

func (a *api) verifyEmailHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req VerifyEmailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid request body"))
		return
	}

	if req.Token == "" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("token is required"))
		return
	}

	_, err := a.accountsRepo.VerifyEmail(ctx, req.Token)
	if err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid or expired verification token"))
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "email verified successfully"})
}

type RequestPasswordResetRequest struct {
	Email string `json:"email"`
}

func (a *api) requestPasswordResetHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req RequestPasswordResetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid request body"))
		return
	}

	// Validate email
	if _, err := mail.ParseAddress(req.Email); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid email address"))
		return
	}

	// Check if account exists
	account, err := a.accountsRepo.GetAccountByEmail(ctx, req.Email)
	if err != nil || account == nil {
		// Don't reveal whether the email exists or not
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"message": "If the email exists, a password reset link has been sent"})
		return
	}

	// Generate password reset token
	token, err := domain.GenerateSecureToken()
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to generate reset token"))
		return
	}

	// Set expiration time (15 minutes from now)
	expiresAt := domain.GetCurrentTimeRFC3339()
	expiresAt, err = domain.AddTimeToRFC3339(expiresAt, 15*time.Minute)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to set expiration time"))
		return
	}

	// Store the token in database
	err = a.accountsRepo.SetPasswordResetToken(ctx, req.Email, token, expiresAt)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to set reset token"))
		return
	}

	// Send password reset email
	err = a.emailService.SendPasswordReset(req.Email, token)
	if err != nil {
		a.logger.Error("Failed to send password reset email", zap.Error(err))
		// Don't fail the request, just log the error
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "If the email exists, a password reset link has been sent"})
}

type ResetPasswordRequest struct {
	Token       string `json:"token"`
	NewPassword string `json:"new_password"`
}

func (a *api) resetPasswordHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req ResetPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid request body"))
		return
	}

	if req.Token == "" || req.NewPassword == "" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("token and new password are required"))
		return
	}

	// Validate password strength
	if len(req.NewPassword) < 8 {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("password must be at least 8 characters long"))
		return
	}

	// Hash the new password
	hashedPassword, err := domain.HashPassword(req.NewPassword)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to hash password"))
		return
	}

	// Reset password using the token
	account, err := a.accountsRepo.ResetPassword(ctx, req.Token, hashedPassword)
	if err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid or expired reset token"))
		return
	}

	// Invalidate all sessions for this user for security
	err = a.accountsRepo.DeleteAllUserSessions(ctx, account.ID)
	if err != nil {
		a.logger.Error("Failed to invalidate user sessions after password reset", zap.Error(err))
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "password reset successfully"})
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

func (a *api) changePasswordHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req ChangePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid request body"))
		return
	}

	if req.CurrentPassword == "" || req.NewPassword == "" {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("current password and new password are required"))
		return
	}

	// Get the current user from session
	account, err := a.getCurrentUser(r)
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}

	// Get full account details to verify current password
	fullAccount, err := a.accountsRepo.GetAccountByID(ctx, account.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to get account"))
		return
	}

	// Verify current password
	if !domain.CheckPasswordHash(req.CurrentPassword, fullAccount.PasswordHash) {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("current password is incorrect"))
		return
	}

	// Validate new password strength
	if len(req.NewPassword) < 8 {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("new password must be at least 8 characters long"))
		return
	}

	// Hash the new password
	hashedPassword, err := domain.HashPassword(req.NewPassword)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to hash password"))
		return
	}

	// Update password in database
	err = a.accountsRepo.ChangePassword(ctx, account.ID, hashedPassword)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to update password"))
		return
	}

	// Invalidate all sessions for this user for security
	err = a.accountsRepo.DeleteAllUserSessions(ctx, account.ID)
	if err != nil {
		a.logger.Error("Failed to invalidate user sessions", zap.Error(err))
	}

	// Create a new session for the user since all sessions were invalidated
	id, token, secretHash := domain.GenerateSession()
	_, err = a.accountsRepo.CreateSession(ctx, id, secretHash, account.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to create new session"))
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Password changed successfully",
		"token":   token,
	})
}

// Helpers
// getCurrentUser extracts the current user from the Authorization header
func (a *api) getCurrentUser(r *http.Request) (*domain.AccountDBModel, error) {
	ctx := r.Context()
	var sessionToken string

	authHeader := r.Header.Get("Authorization")
	if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
		sessionToken = strings.TrimPrefix(authHeader, "Bearer ")
	} else {
		return nil, fmt.Errorf("no session token provided")
	}

	// Validate session token
	session, err := a.accountsRepo.ValidateSessionToken(ctx, sessionToken)
	if err != nil {
		return nil, err
	}
	if session == nil {
		return nil, fmt.Errorf("invalid session")
	}

	// Get account by ID using the AccountID from session
	account, err := a.accountsRepo.GetAccountByID(ctx, session.AccountID)
	if err != nil {
		return nil, err
	}
	if account == nil {
		return nil, fmt.Errorf("account not found")
	}

	return account, nil
}
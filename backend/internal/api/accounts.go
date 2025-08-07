package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/Arjun113/nOPark/internal/domain"
	"go.uber.org/zap"
)

type CreateUserRequest struct {
	Email      string `json:"email" validate:"required,email"`
	Password   string `json:"password" validate:"required,min=8"`
	FirstName  string `json:"first_name" validate:"required"`
	MiddleName string `json:"middle_name,omitempty"`
	LastName   string `json:"last_name" validate:"required"`
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

	var req CreateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	existingAccount, err := a.accountsRepo.GetAccountByEmail(ctx, req.Email)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if existingAccount != nil {
		a.errorResponse(w, r, http.StatusConflict, fmt.Errorf("account with this email already exists"))
		return
	}

	hashedPassword, err := domain.HashPassword(req.Password)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

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

	id, token, secretHash := domain.GenerateSession()
	_, err = a.accountsRepo.CreateSession(ctx, id, secretHash, createdAccount.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

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
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
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

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	account, err := a.accountsRepo.GetAccountByEmail(ctx, req.Email)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}
	if account == nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("incorrect email or password"))
		return
	}

	if !domain.CheckPasswordHash(req.Password, account.PasswordHash) {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("incorrect email or password"))
		return
	}

	id, token, secretHash := domain.GenerateSession()
	_, err = a.accountsRepo.CreateSession(ctx, id, secretHash, account.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

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

	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	session, err := a.accountsRepo.ValidateSessionToken(ctx, sessionToken)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	if session != nil {
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

type GetUserResponse struct {
	Email     string          `json:"email"`
	FirstName string          `json:"first_name"`
	MiddleName string         `json:"middle_name,omitempty"`
	LastName  string          `json:"last_name"`
}

func (a *api) getUserHandler(w http.ResponseWriter, r *http.Request) {
	account, err := a.getUserFromAuthHeader(r)
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
	Token string `json:"token" validate:"required"`
}

func (a *api) verifyEmailHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req VerifyEmailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid request body"))
		return
	}

	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
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
	Email string `json:"email" validate:"required,email"`
}

func (a *api) requestPasswordResetHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req RequestPasswordResetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid request body"))
		return
	}

	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	account, err := a.accountsRepo.GetAccountByEmail(ctx, req.Email)
	if err != nil || account == nil {
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"message": "If the email exists, a password reset link has been sent"})
		return
	}

	token, err := domain.GenerateSecureToken()
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to generate reset token"))
		return
	}

	expiresAt := domain.GetCurrentTimeRFC3339()
	expiresAt, err = domain.AddTimeToRFC3339(expiresAt, 15*time.Minute)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to set expiration time"))
		return
	}

	err = a.accountsRepo.SetPasswordResetToken(ctx, req.Email, token, expiresAt)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to set reset token"))
		return
	}

	err = a.emailService.SendPasswordReset(req.Email, token)
	if err != nil {
		a.logger.Error("Failed to send password reset email", zap.Error(err))
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "If the email exists, a password reset link has been sent"})
}

type ResetPasswordRequest struct {
	Token       string `json:"token" validate:"required"`
	NewPassword string `json:"new_password" validate:"required,min=8"`
}

func (a *api) resetPasswordHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req ResetPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid request body"))
		return
	}

	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	hashedPassword, err := domain.HashPassword(req.NewPassword)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to hash password"))
		return
	}

	account, err := a.accountsRepo.ResetPassword(ctx, req.Token, hashedPassword)
	if err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid or expired reset token"))
		return
	}

	err = a.accountsRepo.DeleteAllUserSessions(ctx, account.ID)
	if err != nil {
		a.logger.Error("Failed to invalidate user sessions after password reset", zap.Error(err))
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "password reset successfully"})
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" validate:"required"`
	NewPassword     string `json:"new_password" validate:"required,min=8"`
}

func (a *api) changePasswordHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req ChangePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid request body"))
		return
	}

	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	account, err := a.getUserFromAuthHeader(r)
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}

	fullAccount, err := a.accountsRepo.GetAccountByID(ctx, account.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to get account"))
		return
	}

	if !domain.CheckPasswordHash(req.CurrentPassword, fullAccount.PasswordHash) {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("current password is incorrect"))
		return
	}

	hashedPassword, err := domain.HashPassword(req.NewPassword)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to hash password"))
		return
	}

	err = a.accountsRepo.ChangePassword(ctx, account.ID, hashedPassword)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to update password"))
		return
	}

	err = a.accountsRepo.DeleteAllUserSessions(ctx, account.ID)
	if err != nil {
		a.logger.Error("Failed to invalidate user sessions", zap.Error(err))
	}

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

func (a *api) getUserFromAuthHeader(r *http.Request) (*domain.AccountDBModel, error) {
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
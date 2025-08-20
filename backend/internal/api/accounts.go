package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/Arjun113/nOPark/internal/repository"
	"go.uber.org/zap"
)

type CreateUserRequest struct {
	Type       string `json:"type" validate:"required,oneof=passenger driver admin"`
	Email      string `json:"email" validate:"required,email,monash_email"`
	Password   string `json:"password" validate:"required,min=8"`
	FirstName  string `json:"first_name" validate:"required"`
	MiddleName string `json:"middle_name"`
	LastName   string `json:"last_name" validate:"required"`
}

type CreateUserResponse struct {
	Type       string `json:"type"`
	Email      string `json:"email"`
	FirstName  string `json:"first_name"`
	MiddleName string `json:"middle_name"`
	LastName   string `json:"last_name"`
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
		Type:         req.Type,
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

	token, err := domain.GenerateSecureToken()
	if err != nil {
		a.logger.Error("Failed to generate email verification token", zap.Error(err))
	} else {
		expiresAt := domain.GetCurrentTimeRFC3339()
		expiresAt, err = domain.AddTimeToRFC3339(expiresAt, 24*time.Hour)
		if err != nil {
			a.logger.Error("Failed to set email verification expiration", zap.Error(err))
		} else {
			err = a.accountsRepo.SetEmailVerificationToken(ctx, fmt.Sprintf("%d", createdAccount.ID), token, expiresAt)
			if err != nil {
				a.logger.Error("Failed to set email verification token", zap.Error(err))
			} else {
				err = a.emailService.SendEmailVerification(createdAccount.Email, token)
				if err != nil {
					a.logger.Error("Failed to send email verification", zap.Error(err))
				}
			}
		}
	}

	response := CreateUserResponse{
		Type:       createdAccount.Type,
		Email:      createdAccount.Email,
		FirstName:  createdAccount.FirstName,
		MiddleName: createdAccount.MiddleName,
		LastName:   createdAccount.LastName,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email,monash_email"`
	Password string `json:"password" validate:"required"`
}

type LoginResponse struct {
	ID         int64  `json:"id"`
	Type       string `json:"type"`
	Email      string `json:"email"`
	FirstName  string `json:"first_name"`
	MiddleName string `json:"middle_name"`
	LastName   string `json:"last_name"`
	Token      string `json:"token"`
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
	if !account.EmailVerified {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("email not verified"))
		return
	}

	id, token, secretHash := domain.GenerateSession()
	_, err = a.accountsRepo.CreateSession(ctx, id, secretHash, account.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := LoginResponse{
		ID:         account.ID,
		Type:       account.Type,
		Email:      account.Email,
		FirstName:  account.FirstName,
		MiddleName: account.MiddleName,
		LastName:   account.LastName,
		Token:      token,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func (a *api) logoutUserHandler(w http.ResponseWriter, r *http.Request) {
	session, ok := repository.GetSessionFromContext(r.Context())
	if !ok {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to get session from context"))
		return
	}

	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	err := a.accountsRepo.DeleteSession(ctx, session.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "logged out successfully"})
}

type GetUserResponse struct {
	Type             string   `json:"type"`
	Email            string   `json:"email"`
	FirstName        string   `json:"first_name"`
	MiddleName       string   `json:"middle_name"`
	LastName         string   `json:"last_name"`
	EmailVerified    bool     `json:"email_verified"`
	CurrentLatitude  *float64 `json:"current_latitude"`
	CurrentLongitude *float64 `json:"current_longitude"`
}

func (a *api) getUserHandler(w http.ResponseWriter, r *http.Request) {
	account, err := a.accountsRepo.GetAccountFromSession(r.Context())
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}

	response := GetUserResponse{
		Type:             account.Type,
		Email:            account.Email,
		FirstName:        account.FirstName,
		MiddleName:       account.MiddleName,
		LastName:         account.LastName,
		EmailVerified:    account.EmailVerified,
		CurrentLatitude:  account.CurrentLatitude,
		CurrentLongitude: account.CurrentLongitude,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

type VerifyEmailRequest struct {
	Email string `json:"email" validate:"required,email,monash_email"`
	Token string `json:"token" validate:"required"`
}

type VerifyEmailResponse struct {
	Message string `json:"message"`
	Email   string `json:"email"`
	Token   string `json:"token"`
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

	account, err := a.accountsRepo.VerifyEmail(ctx, req.Token)
	if err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid or expired verification token"))
		return
	}

	id, token, secretHash := domain.GenerateSession()
	_, err = a.accountsRepo.CreateSession(ctx, id, secretHash, account.ID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := &VerifyEmailResponse{
		Message: "email verified successfully",
		Email:   account.Email,
		Token:   token,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

type RequestPasswordResetRequest struct {
	Email string `json:"email" validate:"required,email,monash_email"`
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

	account, err := a.accountsRepo.GetAccountFromSession(r.Context())
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
	json.NewEncoder(w).Encode(map[string]any{
		"message": "Password changed successfully",
		"token":   token,
	})
}

type UpdateUserRequest struct {
	Type             string   `json:"type" validate:"omitempty,oneof=passenger driver"`
	Email            string   `json:"email" validate:"email,monash_email"`
	FirstName        string   `json:"first_name"`
	MiddleName       string   `json:"middle_name"`
	LastName         string   `json:"last_name"`
	CurrentLatitude  *float64 `json:"current_latitude"`
	CurrentLongitude *float64 `json:"current_longitude"`
}

type UpdateUserResponse struct {
	Type             string   `json:"type"`
	Email            string   `json:"email"`
	FirstName        string   `json:"first_name"`
	MiddleName       string   `json:"middle_name"`
	LastName         string   `json:"last_name"`
	EmailVerified    bool     `json:"email_verified"`
	CurrentLatitude  *float64 `json:"current_latitude"`
	CurrentLongitude *float64 `json:"current_longitude"`
	Message          string   `json:"message"`
}

func (a *api) updateUserHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	account, err := a.accountsRepo.GetAccountFromSession(r.Context())
	if err != nil {
		a.errorResponse(w, r, http.StatusUnauthorized, fmt.Errorf("authentication required"))
		return
	}

	var req UpdateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	if err := a.validateRequest(req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
		return
	}

	updatedAccount := &domain.AccountDBModel{
		ID:               account.ID,
		Type:             account.Type,
		Email:            account.Email,
		FirstName:        account.FirstName,
		MiddleName:       account.MiddleName,
		LastName:         account.LastName,
		EmailVerified:    account.EmailVerified,
		CurrentLatitude:  account.CurrentLatitude,
		CurrentLongitude: account.CurrentLongitude,
	}

	// Update only the fields that are provided
	emailChanged := false
	if req.Email != "" && req.Email != account.Email {
		// Check if the new email is already in use
		existingAccount, err := a.accountsRepo.GetAccountByEmail(ctx, req.Email)
		if err != nil {
			a.errorResponse(w, r, http.StatusInternalServerError, err)
			return
		}
		if existingAccount != nil {
			a.errorResponse(w, r, http.StatusConflict, fmt.Errorf("email already in use"))
			return
		}

		updatedAccount.Email = req.Email
		updatedAccount.EmailVerified = false // Reset verification when email changes
		emailChanged = true
	}

	if req.Type != "" {
		updatedAccount.Type = req.Type
	}
	if req.FirstName != "" {
		updatedAccount.FirstName = req.FirstName
	}
	if req.MiddleName != "" {
		updatedAccount.MiddleName = req.MiddleName
	}
	if req.LastName != "" {
		updatedAccount.LastName = req.LastName
	}
	if req.CurrentLatitude != nil {
		updatedAccount.CurrentLatitude = req.CurrentLatitude
	}
	if req.CurrentLongitude != nil {
		updatedAccount.CurrentLongitude = req.CurrentLongitude
	}

	if req.Type == "" && req.Email == "" && req.FirstName == "" && req.MiddleName == "" && req.LastName == "" &&
		req.CurrentLatitude == nil && req.CurrentLongitude == nil {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("no fields to update"))
		return
	}

	acc, err := a.accountsRepo.UpdateAccount(ctx, updatedAccount)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, err)
		return
	}

	response := UpdateUserResponse{
		Type:             acc.Type,
		Email:            acc.Email,
		FirstName:        acc.FirstName,
		MiddleName:       acc.MiddleName,
		LastName:         acc.LastName,
		EmailVerified:    acc.EmailVerified,
		CurrentLatitude:  acc.CurrentLatitude,
		CurrentLongitude: acc.CurrentLongitude,
	}

	if emailChanged {
		token, err := domain.GenerateSecureToken()
		if err != nil {
			a.logger.Error("Failed to generate email verification token", zap.Error(err))
		} else {
			expiresAt := domain.GetCurrentTimeRFC3339()
			expiresAt, err = domain.AddTimeToRFC3339(expiresAt, 24*time.Hour)
			if err != nil {
				a.logger.Error("Failed to set email verification expiration", zap.Error(err))
			} else {
				err = a.accountsRepo.SetEmailVerificationToken(ctx, fmt.Sprintf("%d", acc.ID), token, expiresAt)
				if err != nil {
					a.logger.Error("Failed to set email verification token", zap.Error(err))
				} else {
					err = a.emailService.SendEmailVerification(acc.Email, token)
					if err != nil {
						a.logger.Error("Failed to send email verification", zap.Error(err))
					}
				}
			}
		}
		response.Message = "Profile updated successfully. A verification email has been sent to your new email address."
	} else {
		response.Message = "Profile updated successfully."
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

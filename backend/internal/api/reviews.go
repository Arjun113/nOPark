package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/gorilla/mux"
)

type CreateReviewRequest struct {
	Stars   int    `json:"stars" validate:"required,min=1,max=5"`
	Comment string `json:"comment" validate:"required,max=250"`
}

type CreateReviewResponse struct {
	ID         int64  `json:"id"`
	Stars      int    `json:"stars"`
	Comment    string `json:"comment"`
	ReviewerID int64  `json:"reviewer_id"`
	RevieweeID int64  `json:"reviewee_id"`
	CreatedAt  string `json:"created_at"`
	Message    string `json:"message"`
}

func (a *api) createReviewHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	// Extract the user ID from the URL path
	vars := mux.Vars(r)
	revieweeIDStr, ok := vars["id"]
	if !ok {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("missing user id in path"))
		return
	}

	revieweeID, err := strconv.ParseInt(revieweeIDStr, 10, 64)
	if err != nil || revieweeID <= 0 {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("invalid user id"))
		return
	}

	var req CreateReviewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.errorResponse(w, r, http.StatusBadRequest, err)
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

	// Check if the reviewer is trying to review themselves
	if account.ID == revieweeID {
		a.errorResponse(w, r, http.StatusBadRequest, fmt.Errorf("you cannot review yourself"))
		return
	}

	// Verify the reviewee exists
	revieweeAccount, err := a.accountsRepo.GetAccountByID(ctx, revieweeID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to fetch reviewee account: %w", err))
		return
	}
	if revieweeAccount == nil {
		a.errorResponse(w, r, http.StatusNotFound, fmt.Errorf("user to review not found"))
		return
	}

	// Check if this person has already reviewed this user before
	existingReview, err := a.reviewsRepo.GetReviewByReviewerAndReviewee(ctx, account.ID, revieweeID)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to check for existing review: %w", err))
		return
	}
	if existingReview != nil {
		a.errorResponse(w, r, http.StatusConflict, fmt.Errorf("you have already reviewed this user"))
		return
	}

	// Create the review
	review := &domain.ReviewDBModel{
		Stars:      req.Stars,
		Comment:    req.Comment,
		ReviewerID: account.ID,
		RevieweeID: revieweeID,
	}

	createdReview, err := a.reviewsRepo.CreateReview(ctx, review)
	if err != nil {
		a.errorResponse(w, r, http.StatusInternalServerError, fmt.Errorf("failed to create review: %w", err))
		return
	}

	response := CreateReviewResponse{
		ID:         createdReview.ID,
		Stars:      createdReview.Stars,
		Comment:    createdReview.Comment,
		ReviewerID: createdReview.ReviewerID,
		RevieweeID: createdReview.RevieweeID,
		CreatedAt:  createdReview.CreatedAt,
		Message:    "Review created successfully",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

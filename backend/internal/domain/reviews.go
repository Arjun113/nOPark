package domain

import "context"

type ReviewsRepository interface {
	CreateReview(ctx context.Context, review *ReviewDBModel) (*ReviewDBModel, error)
	GetReviewsForUser(ctx context.Context, userID int64) ([]*ReviewDBModel, error)
	GetUserRating(ctx context.Context, userID int64) (*float64, int64, error)
	GetReviewByReviewerAndReviewee(ctx context.Context, reviewerID, revieweeID int64) (*ReviewDBModel, error)
}

type ReviewDBModel struct {
	ID         int64
	Stars      int
	Comment    string
	ReviewerID int64
	RevieweeID int64
	CreatedAt  string
}

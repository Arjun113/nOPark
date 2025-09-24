package repository

import (
	"context"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/jackc/pgx/v5"
)

type postgresReviewsRepository struct {
	conn Connection
}

func NewPostgresReviews(conn Connection) domain.ReviewsRepository {
	return &postgresReviewsRepository{conn: conn}
}

func (p *postgresReviewsRepository) CreateReview(ctx context.Context, review *domain.ReviewDBModel) (*domain.ReviewDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`INSERT INTO reviews (stars, comment, reviewer_id, reviewee_id) VALUES ($1, $2, $3, $4) RETURNING id, stars, comment, reviewer_id, reviewee_id, created_at`,
		review.Stars, review.Comment, review.ReviewerID, review.RevieweeID)

	var r domain.ReviewDBModel
	err := row.Scan(&r.ID, &r.Stars, &r.Comment, &r.ReviewerID, &r.RevieweeID, &r.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &r, nil
}

func (p *postgresReviewsRepository) GetReviewsForUser(ctx context.Context, userID int64) ([]*domain.ReviewDBModel, error) {
	rows, err := p.conn.Query(ctx,
		`SELECT id, stars, comment, reviewer_id, reviewee_id, created_at FROM reviews WHERE reviewee_id = $1 ORDER BY created_at DESC`,
		userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	reviews := []*domain.ReviewDBModel{}
	for rows.Next() {
		var r domain.ReviewDBModel
		err := rows.Scan(&r.ID, &r.Stars, &r.Comment, &r.ReviewerID, &r.RevieweeID, &r.CreatedAt)
		if err != nil {
			return nil, err
		}
		reviews = append(reviews, &r)
	}
	return reviews, nil
}

func (p *postgresReviewsRepository) GetUserRating(ctx context.Context, userID int64) (*float64, int64, error) {
	row := p.conn.QueryRow(ctx,
		`SELECT AVG(stars), COUNT(*) FROM reviews WHERE reviewee_id = $1`, userID)
	var avgRating *float64
	var numRatings int64
	err := row.Scan(&avgRating, &numRatings)
	if err != nil {
		return nil, 0, err
	}
	return avgRating, numRatings, nil
}

func (p *postgresReviewsRepository) GetReviewByReviewerAndReviewee(ctx context.Context, reviewerID, revieweeID int64) (*domain.ReviewDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`SELECT id, stars, comment, reviewer_id, reviewee_id, created_at FROM reviews WHERE reviewer_id = $1 AND reviewee_id = $2 ORDER BY created_at DESC LIMIT 1`,
		reviewerID, revieweeID)

	var r domain.ReviewDBModel
	err := row.Scan(&r.ID, &r.Stars, &r.Comment, &r.ReviewerID, &r.RevieweeID, &r.CreatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil // No review found
		}
		return nil, err
	}
	return &r, nil
}

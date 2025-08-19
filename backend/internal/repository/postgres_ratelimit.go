package repository

import (
	"context"
	"time"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/jackc/pgx/v5"
)

type postgresRatelimitRepository struct {
	conn Connection
}

func NewPostgresRatelimit(conn Connection) domain.RatelimitRepository {
	return &postgresRatelimitRepository{conn: conn}
}

func (p *postgresRatelimitRepository) GetRateLimit(ctx context.Context, ipAddress string) (*domain.RatelimitDBModel, error) {
	query := `
		SELECT ip_address, tokens, last_request
		FROM rate_limits 
		WHERE ip_address = $1
	`

	var record domain.RatelimitDBModel
	err := p.conn.QueryRow(ctx, query, ipAddress).Scan(
		&record.IPAddress,
		&record.Tokens,
		&record.LastRequest,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			record = domain.RatelimitDBModel{
				IPAddress:   ipAddress,
				Tokens:      domain.DefaultRateLimitConfig.InitialToken,
				LastRequest: time.Now(),
			}

			_, err = p.conn.Exec(ctx,
				`INSERT INTO rate_limits (ip_address, tokens, last_request)
				VALUES ($1, $2, $3)`,
				record.IPAddress, record.Tokens, record.LastRequest,
			)
			if err != nil {
				return nil, err
			}

			return &record, nil
		}
		return nil, err
	}

	return &record, nil
}

func (p *postgresRatelimitRepository) UpdateRateLimit(ctx context.Context, record *domain.RatelimitDBModel) error {
	_, err := p.conn.Exec(ctx,
		`UPDATE rate_limits SET tokens = $1, last_request = $2 WHERE ip_address = $3`,
		record.Tokens, record.LastRequest, record.IPAddress,
	)
	return err
}

func (p *postgresRatelimitRepository) IsIPBlocked(ctx context.Context, ipAddress string) (bool, time.Time, error) {

	var expiresAt time.Time
	err := p.conn.QueryRow(ctx,
		`SELECT expires_at FROM ip_blacklist WHERE ip_address = $1 AND expires_at > NOW()`,
		ipAddress).Scan(&expiresAt)

	if err != nil {
		if err == pgx.ErrNoRows {
			return false, time.Time{}, nil
		}
		return false, time.Time{}, err
	}

	return true, expiresAt, nil
}

func (p *postgresRatelimitRepository) BlockIP(ctx context.Context, ipAddress string, reason string, duration time.Duration) error {
	expiresAt := time.Now().Add(duration)

	_, err := p.conn.Exec(ctx,
		`INSERT INTO ip_blacklist (ip_address, reason, expires_at) VALUES ($1, $2, $3)
		ON CONFLICT (ip_address) DO UPDATE SET reason = $2, expires_at = $3`,
		ipAddress, reason, expiresAt)
	return err
}

func (p *postgresRatelimitRepository) UnblockIP(ctx context.Context, ipAddress string) error {
	_, err := p.conn.Exec(ctx, `DELETE FROM ip_blacklist WHERE ip_address = $1`, ipAddress)
	return err
}

// CleanupExpiredBlocks removes expired entries from IP blacklist
func (p *postgresRatelimitRepository) CleanupExpiredBlocks(ctx context.Context) (int, error) {

	rows, err := p.conn.Query(ctx, `DELETE FROM ip_blacklist WHERE expires_at <= NOW() RETURNING ip_address`)
	if err != nil {
		return 0, err
	}
	defer rows.Close()

	var count int
	for rows.Next() {
		count++
	}

	return count, rows.Err()
}

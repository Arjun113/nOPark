package domain

import (
	"context"
	"time"
)

type RatelimitDBModel struct {
	IPAddress   string
	Tokens      float64
	LastRequest time.Time
}

type IPBlockDBModel struct {
	IPAddress string
	Reason    string
	ExpiresAt time.Time
}

type RateLimitConfig struct {
	InitialToken  float64
	MaxTokens     float64
	TokensPerSec  float64
	BlockDuration time.Duration
}

var DefaultRateLimitConfig = RateLimitConfig{
	InitialToken:  10.0,
	MaxTokens:     10.0,
	TokensPerSec:  0.5,              // 0.5 tokens per second (30 requests per minute)
	BlockDuration: 30 * time.Minute, // Block for 30 minutes after violations
}

type RatelimitRepository interface {
	GetRateLimit(ctx context.Context, ipAddress string) (*RatelimitDBModel, error)
	UpdateRateLimit(ctx context.Context, record *RatelimitDBModel) error
	IsIPBlocked(ctx context.Context, ipAddress string) (bool, time.Time, error)
	BlockIP(ctx context.Context, ipAddress string, reason string, duration time.Duration) error
	UnblockIP(ctx context.Context, ipAddress string) error
	CleanupExpiredBlocks(ctx context.Context) (int, error)
}

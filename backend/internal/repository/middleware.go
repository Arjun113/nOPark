package repository

import (
	"context"
	"fmt"
	"math"
	"math/rand"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/gofrs/uuid"
	"go.uber.org/zap"
)

// LoggingResponseWriter wraps http.ResponseWriter to capture response data for logging
type LoggingResponseWriter struct {
	w          http.ResponseWriter
	statusCode int
	bytes      int
}

func (lrw *LoggingResponseWriter) Header() http.Header {
	return lrw.w.Header()
}

func (lrw *LoggingResponseWriter) Write(bb []byte) (int, error) {
	wb, err := lrw.w.Write(bb)
	lrw.bytes += wb
	return wb, err
}

func (lrw *LoggingResponseWriter) WriteHeader(statusCode int) {
	lrw.w.WriteHeader(statusCode)
	lrw.statusCode = statusCode
}

// RequestIdMiddleware adds a unique request ID header to each request
func RequestIdMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := uuid.Must(uuid.NewV4()).String()
		w.Header().Set("X-nOPark-Request-Id", id)
		next.ServeHTTP(w, r)
	})
}

// NewLoggingMiddleware logs HTTP requests with response time, status, and other details
func NewLoggingMiddleware(logger *zap.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Skip logging health checks
			if r.RequestURI == "/v1/health" {
				next.ServeHTTP(w, r)
				return
			}

			start := time.Now()
			lrw := &LoggingResponseWriter{w: w}

			// Call the next handler, which can be another middleware in the chain, or the final handler.
			next.ServeHTTP(lrw, r)

			duration := time.Since(start).Milliseconds()

			remoteAddr := r.Header.Get("X-Forwarded-For")
			if remoteAddr == "" {
				if ip, _, err := net.SplitHostPort(r.RemoteAddr); err != nil {
					remoteAddr = "unknown"
				} else {
					remoteAddr = ip
				}
			}

			fields := []zap.Field{
				zap.Int64("duration", duration),
				zap.String("method", r.Method),
				zap.String("remote#addr", remoteAddr),
				zap.Int("response#bytes", lrw.bytes),
				zap.Int("status", lrw.statusCode),
				zap.String("uri", r.RequestURI),
				zap.String("request#id", lrw.Header().Get("X-nOPark-Request-Id")),
			}

			if lrw.statusCode >= 200 && lrw.statusCode < 300 {
				logger.Info("", fields...)
			} else {
				err := lrw.Header().Get("X-nOPark-Error")
				logger.Error(err, fields...)
			}
		})
	}
}

// Context keys for storing authentication data
type contextKey string

const (
	sessionContextKey = contextKey("session")
)

// AuthMiddleware validates bearer tokens and stores session information in context
func AuthMiddleware(accountsRepo domain.AccountsRepository) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx := r.Context()
			var sessionToken string

			// Extract bearer token from Authorization header
			authHeader := r.Header.Get("Authorization")
			if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
				sessionToken = strings.TrimPrefix(authHeader, "Bearer ")
			} else {
				http.Error(w, "authorization header required", http.StatusUnauthorized)
				return
			}

			// Validate session token
			session, err := accountsRepo.ValidateSessionToken(ctx, sessionToken)
			if err != nil {
				http.Error(w, "authentication failed", http.StatusUnauthorized)
				return
			}
			if session == nil {
				http.Error(w, "invalid session", http.StatusUnauthorized)
				return
			}

			// Store session in context
			ctx = context.WithValue(ctx, sessionContextKey, session)

			// Continue with the authenticated request
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// GetSessionFromContext retrieves the session from the request context
func GetSessionFromContext(ctx context.Context) (*domain.SessionDBModel, bool) {
	session, ok := ctx.Value(sessionContextKey).(*domain.SessionDBModel)
	return session, ok
}

// RateLimitMiddleware implements token bucket algorithm for rate limiting API requests (incls IP blocking)
func RateLimitMiddleware(repo domain.RatelimitRepository, logger *zap.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

			if r.URL.Path == "/v1/health" {
				next.ServeHTTP(w, r)
				return
			}

			ip := getClientIP(r)
			print(ip)

			blocked, expiresAt, err := repo.IsIPBlocked(r.Context(), ip)
			if err != nil {
				logger.Error("Failed to check IP block status", zap.Error(err))
			} else if blocked {
				w.Header().Set("Retry-After", fmt.Sprintf("%d", int(time.Until(expiresAt).Seconds())))
				http.Error(w, "IP is blocked.", http.StatusTooManyRequests)
				return
			}

			// Occasionally clean up expired IP blocks (0.1% chance per request)
			if rand.Float64() < 0.001 {
				go func() {
					ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
					defer cancel()
					count, err := repo.CleanupExpiredBlocks(ctx)
					if err != nil {
						logger.Error("Failed to clean up expired IP blocks", zap.Error(err))
					} else if count > 0 {
						logger.Info("Cleaned up expired IP blocks", zap.Int("count", count))
					}
				}()
			}

			// Get or create rate limit record for this IP
			record, err := repo.GetRateLimit(r.Context(), ip)
			if err != nil {
				logger.Error("Failed to get rate limit record", zap.Error(err))
				next.ServeHTTP(w, r)
				return
			}

			// Apply token bucket algorithm
			now := time.Now()
			timePassed := now.Sub(record.LastRequest).Seconds()
			tokensToAdd := timePassed * domain.DefaultRateLimitConfig.TokensPerSec

			// Add tokens based on time passed, up to the maximum
			newTokens := record.Tokens + tokensToAdd
			if newTokens > domain.DefaultRateLimitConfig.MaxTokens {
				newTokens = domain.DefaultRateLimitConfig.MaxTokens
			}

			// Check if enough tokens are available
			if newTokens < 1.0 {
				// Not enough tokens, reject the request
				// If severely abusing limits, block the IP
				if newTokens < -5.0 {
					err = repo.BlockIP(r.Context(), ip, "Rate limit exceeded", domain.DefaultRateLimitConfig.BlockDuration)
					if err != nil {
						logger.Error("Failed to block IP", zap.Error(err))
					} else {
						logger.Warn("IP blocked for excessive requests",
							zap.String("ip", ip),
							zap.Duration("duration", domain.DefaultRateLimitConfig.BlockDuration))
					}
				}

				// Calculate time needed to get 1 token
				retryAfter := int(math.Ceil((1.0 - newTokens) / domain.DefaultRateLimitConfig.TokensPerSec))

				// Set rate limit headers
				w.Header().Set("Retry-After", fmt.Sprintf("%d", retryAfter))
				w.Header().Set("X-RateLimit-Limit", fmt.Sprintf("%d", int(domain.DefaultRateLimitConfig.MaxTokens)))
				w.Header().Set("X-RateLimit-Remaining", "0")

				// Return 429 Too Many Requests
				http.Error(w, "Rate limit exceeded. Please slow down your requests.", http.StatusTooManyRequests)

				// Update the record with negative tokens to track abuse
				record.Tokens = newTokens
				record.LastRequest = now
				if err := repo.UpdateRateLimit(r.Context(), record); err != nil {
					logger.Error("Failed to update rate limit", zap.Error(err))
				}

				return
			}

			// Consume one token and update the record
			record.Tokens = newTokens - 1.0
			record.LastRequest = now
			if err := repo.UpdateRateLimit(r.Context(), record); err != nil {
				logger.Error("Failed to update rate limit", zap.Error(err))
			}

			// Set rate limit headers
			w.Header().Set("X-RateLimit-Limit", fmt.Sprintf("%d", int(domain.DefaultRateLimitConfig.MaxTokens)))
			w.Header().Set("X-RateLimit-Remaining", fmt.Sprintf("%d", int(math.Floor(record.Tokens))))

			// Process the request
			next.ServeHTTP(w, r)
		})
	}
}

// getClientIP extracts the client's real IP address
func getClientIP(r *http.Request) string {
	// Check for X-Forwarded-For header first (for proxies)
	ip := r.Header.Get("X-Forwarded-For")
	if ip != "" {
		// X-Forwarded-For can contain multiple IPs; use the first one
		ips := strings.Split(ip, ",")
		return strings.TrimSpace(ips[0])
	}

	// Fallback to RemoteAddr
	if ip, _, err := net.SplitHostPort(r.RemoteAddr); err == nil {
		return ip
	}

	return r.RemoteAddr
}

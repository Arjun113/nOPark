package repository

import (
	"context"
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

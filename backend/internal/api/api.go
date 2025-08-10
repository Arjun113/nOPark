package api

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/Arjun113/nOPark/internal/repository"
	"github.com/Arjun113/nOPark/internal/services/email"
	"github.com/go-playground/validator/v10"
	"github.com/gofrs/uuid"
	"github.com/gorilla/mux"
	"github.com/jackc/pgx/v5/pgxpool"
	"go.uber.org/zap"
)

type api struct {
	logger       *zap.Logger
	httpClient   *http.Client
	emailService *email.Service
	validator    *validator.Validate

	accountsRepo domain.AccountsRepository
	// mapsRepo          domain.MapsRepository
	ridesRepo		domain.RidesRepository
	
}

func NewAPI(ctx context.Context, logger *zap.Logger, pool *pgxpool.Pool) *api {

	accountsRepo := repository.NewPostgresAccounts(pool)
	// mapsRepo := repository.NewPostgresMaps(pool)
	ridesRepo := repository.NewPostgresRides(pool)

	client := &http.Client{}
	emailService := email.NewService()
	validate := validator.New()

	return &api{
		logger:       logger,
		httpClient:   client,
		emailService: emailService,
		validator:    validate,

		accountsRepo: accountsRepo,
		// mapsRepo:  mapsRepo,
		ridesRepo: ridesRepo,
	}
}

func (a *api) Server(port int) *http.Server {
	return &http.Server{
		Addr:    fmt.Sprintf(":%d", port),
		Handler: a.Routes(),
	}
}

func (a *api) Routes() *mux.Router {
	r := mux.NewRouter()

	r.HandleFunc("/v1/health", a.healthCheckHandler).Methods("GET")

	r.HandleFunc("/v1/accounts", a.createUserHandler).Methods("POST")
	r.HandleFunc("/v1/accounts", a.updateUserHandler).Methods("PUT")
	r.HandleFunc("/v1/accounts/{userID}", a.getUserHandler).Methods("GET")
	r.HandleFunc("/v1/accounts/login", a.loginUserHandler).Methods("POST")
	r.HandleFunc("/v1/accounts/logout", a.logoutUserHandler).Methods("POST")
	r.HandleFunc("/v1/accounts/verify-email", a.verifyEmailHandler).Methods("POST")
	r.HandleFunc("/v1/accounts/request-password-reset", a.requestPasswordResetHandler).Methods("POST")
	r.HandleFunc("/v1/accounts/reset-password", a.resetPasswordHandler).Methods("POST")
	r.HandleFunc("/v1/accounts/change-password", a.changePasswordHandler).Methods("POST")

	// r.HandleFunc("/v1/rides", a.listRidesHandler).Methods("GET")
	r.HandleFunc("/v1/rides/requests", a.getRideRequestsHandler).Methods("GET")
	r.HandleFunc("/v1/rides/requests", a.createRideRequestHandler).Methods("POST")
	// r.HandleFunc("/v1/rides/{rideID}", a.getRideHandler).Methods("GET")
	// r.HandleFunc("/v1/rides/{rideID}", a.updateRideHandler).Methods("PUT")
	// r.HandleFunc("/v1/rides/{rideID}", a.deleteRideHandler).Methods("DELETE")
	
	// r.HandleFunc("/v1/maps", a.listMapsHandler).Methods("GET")
	// r.HandleFunc("/v1/maps", a.createMapHandler).Methods("POST")
	// r.HandleFunc("/v1/maps/{mapID}", a.getMapHandler).Methods("GET")
	// r.HandleFunc("/v1/maps/{mapID}", a.updateMapHandler).Methods("PUT")
	// r.HandleFunc("/v1/maps/{mapID}", a.deleteMapHandler).Methods("DELETE")

	r.Use(a.loggingMiddleware)
	r.Use(a.requestIdMiddleware)

	return r
}

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

func (a *api) requestIdMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := uuid.Must(uuid.NewV4()).String()
		w.Header().Set("X-nOPark-Request-Id", id)
		next.ServeHTTP(w, r)
	})
}

func (a *api) loggingMiddleware(next http.Handler) http.Handler {
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
			a.logger.Info("", fields...)
		} else {
			err := lrw.Header().Get("X-nOPark-Error")
			a.logger.Error(err, fields...)
		}
	})
}

func (a *api) errorResponse(w http.ResponseWriter, _ *http.Request, status int, err error) {
	w.Header().Set("X-nOPark-Error", err.Error())
	http.Error(w, err.Error(), status)
}

func (a *api) validateRequest(req any) error {
	if err := a.validator.Struct(req); err != nil {
		if validationErrors, ok := err.(validator.ValidationErrors); ok {
			for _, fieldError := range validationErrors {
				fieldName := a.getFieldDisplayName(fieldError.Field())
				switch fieldError.Tag() {
				case "required":
					return fmt.Errorf("%s is required", fieldName)
				case "email":
					return fmt.Errorf("invalid email format")
				case "min":
					return fmt.Errorf("%s must be at least %s characters long", fieldName, fieldError.Param())
				default:
					return fmt.Errorf("validation failed for %s", fieldName)
				}
			}
		}
		return err
	}
	return nil
}

func (a *api) getFieldDisplayName(fieldName string) string {
	var result []string
	var current string
	
	for i, char := range fieldName {
		if i > 0 && char >= 'A' && char <= 'Z' {
			if current != "" {
				result = append(result, strings.ToLower(current))
			}
			current = string(char)
		} else {
			current += string(char)
		}
	}
	
	if current != "" {
		result = append(result, strings.ToLower(current))
	}
	
	return strings.Join(result, " ")
}
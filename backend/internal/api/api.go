package api

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"time"

	"github.com/gofrs/uuid"
	"github.com/gorilla/mux"
	"github.com/jackc/pgx/v5/pgxpool"
	"go.uber.org/zap"
	// "github.com/Arjun113/nOPark/internal/domain"
	// "github.com/Arjun113/nOPark/internal/repository"
)

type api struct {
	logger     *zap.Logger
	httpClient *http.Client

	// usersRepo         domain.UsersRepository
	// mapsRepo          domain.MapsRepository
	// ridesRepo		domain.RidesRepository
	
}

func NewAPI(ctx context.Context, logger *zap.Logger, pool *pgxpool.Pool) *api {

	// usersRepo := repository.NewPostgresUsers(pool)
	// mapsRepo := repository.NewPostgresMaps(pool)
	// ridesRepo := repository.NewPostgresRides(pool)

	client := &http.Client{}

	return &api{
		logger:     logger,
		httpClient: client,

		// usersRepo: usersRepo,
		// mapsRepo:  mapsRepo,
		// ridesRepo: ridesRepo,
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

	// r.HandleFunc("/v1/health", a.healthCheckHandler).Methods("GET")

	// r.HandleFunc("/v1/users", a.listUsersHandler).Methods("GET")
	// r.HandleFunc("/v1/users", a.createUserHandler).Methods("POST")
	// r.HandleFunc("/v1/users/{userID}", a.getUserHandler).Methods("GET")
	// r.HandleFunc("/v1/users/{userID}", a.updateUserHandler).Methods("PUT")
	// r.HandleFunc("/v1/users/{userID}", a.deleteUserHandler).Methods("DELETE")

	// r.HandleFunc("/v1/rides", a.listRidesHandler).Methods("GET")
	// r.HandleFunc("/v1/rides", a.createRideHandler).Methods("POST")
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
			zap.String("request#id", lrw.Header().Get("X-Apollo-Request-Id")),
		}

		if lrw.statusCode == 200 {
			a.logger.Info("", fields...)
		} else {
			err := lrw.Header().Get("X-Apollo-Error")
			a.logger.Error(err, fields...)
		}
	})
}
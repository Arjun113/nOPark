package api

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/Arjun113/nOPark/internal/repository"
	"github.com/Arjun113/nOPark/internal/services/email"
	"github.com/go-playground/validator/v10"
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
	ridesRepo domain.RidesRepository
}

func NewAPI(ctx context.Context, logger *zap.Logger, pool *pgxpool.Pool) *api {

	accountsRepo := repository.NewPostgresAccounts(pool)
	// mapsRepo := repository.NewPostgresMaps(pool)
	ridesRepo := repository.NewPostgresRides(pool)

	client := &http.Client{}
	emailService := email.NewService()
	validate := validator.New()
	validate.RegisterValidation("monash_email", MonashEmail)

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

	// Apply global middleware
	r.Use(repository.NewLoggingMiddleware(a.logger))
	r.Use(repository.RequestIdMiddleware)

	// Public routes
	r.HandleFunc("/v1/health", a.healthCheckHandler).Methods("GET")
	r.HandleFunc("/v1/accounts", a.createUserHandler).Methods("POST")
	r.HandleFunc("/v1/accounts/verify-email", a.verifyEmailHandler).Methods("POST")
	r.HandleFunc("/v1/accounts/login", a.loginUserHandler).Methods("POST")
	r.HandleFunc("/v1/accounts/request-password-reset", a.requestPasswordResetHandler).Methods("POST")
	r.HandleFunc("/v1/accounts/reset-password", a.resetPasswordHandler).Methods("POST")

	// Protected routes - require authentication
	p := r.NewRoute().Subrouter()
	p.Use(repository.AuthMiddleware(a.accountsRepo))

	// Protected account routes
	p.HandleFunc("/v1/accounts", a.updateUserHandler).Methods("PUT")
	p.HandleFunc("/v1/accounts", a.getUserHandler).Methods("GET")
	p.HandleFunc("/v1/accounts/logout", a.logoutUserHandler).Methods("POST")
	p.HandleFunc("/v1/accounts/change-password", a.changePasswordHandler).Methods("POST")

	// Protected ride routes
	p.HandleFunc("/v1/rides/requests", a.getRideRequestsHandler).Methods("GET")
	p.HandleFunc("/v1/rides/requests", a.createRideRequestHandler).Methods("POST")
	p.HandleFunc("/v1/rides/", a.createRideDraftHandler).Methods("POST")
	p.HandleFunc("/v1/rides/confirm", a.confirmRideProposalHandler).Methods("POST")
	p.HandleFunc("/v1/rides/summary", a.getRideSummaryHandler).Methods("GET")
	// p.HandleFunc("/rides", a.listRidesHandler).Methods("GET")
	// p.HandleFunc("/rides/{rideID}", a.getRideHandler).Methods("GET")
	// p.HandleFunc("/rides/{rideID}", a.updateRideHandler).Methods("PUT")
	// p.HandleFunc("/rides/{rideID}", a.deleteRideHandler).Methods("DELETE")

	// Protected map routes (commented out for now)
	// p.HandleFunc("/maps", a.listMapsHandler).Methods("GET")
	// p.HandleFunc("/maps", a.createMapHandler).Methods("POST")
	// p.HandleFunc("/maps/{mapID}", a.getMapHandler).Methods("GET")
	// p.HandleFunc("/maps/{mapID}", a.updateMapHandler).Methods("PUT")
	// p.HandleFunc("/maps/{mapID}", a.deleteMapHandler).Methods("DELETE")

	return r
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
				case "monash_email":
					return fmt.Errorf("email must be a valid Monash email address")
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

func MonashEmail(fl validator.FieldLevel) bool {
	email := fl.Field().String()
	atIdx := strings.Index(email, "@")
	if atIdx == -1 {
		return false
	}
	domain := email[atIdx+1:]
	if !strings.Contains(domain, "monash") {
		return false
	}
	if !strings.HasSuffix(domain, ".edu") {
		return false
	}
	return true
}

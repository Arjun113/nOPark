package repository

import (
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"fmt"
	"strings"
	"time"

	"github.com/Arjun113/nOPark/internal/domain"
	"github.com/jackc/pgx/v5"
)

type postgresAccountsRepository struct {
	conn Connection
}

func NewPostgresAccounts(conn Connection) domain.AccountsRepository {
	return &postgresAccountsRepository{conn: conn}
}

func (p *postgresAccountsRepository) CreateAccount(ctx context.Context, acc *domain.AccountDBModel) (*domain.AccountDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`INSERT INTO accounts (type, email, password_hash, firstname, middlename, lastname, fcm_token) 
		 VALUES ($1, $2, $3, $4, $5, $6, $7) 
		 RETURNING id, type, email, firstname, middlename, lastname, email_verified, fcm_token, created_at, updated_at`,
		acc.Type, acc.Email, acc.PasswordHash, acc.FirstName, acc.MiddleName, acc.LastName, acc.FCMToken)

	var account domain.AccountDBModel
	err := row.Scan(&account.ID, &account.Type, &account.Email, &account.FirstName, &account.MiddleName,
		&account.LastName, &account.EmailVerified, &account.FCMToken, &account.CreatedAt, &account.UpdatedAt)
	if err != nil {
		return nil, err
	}

	return &account, nil
}

func (p *postgresAccountsRepository) GetAccountByEmail(ctx context.Context, email string) (*domain.AccountDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`SELECT id, type, email, password_hash, firstname, middlename, lastname, email_verified,
		        current_latitude, current_longitude, fcm_token, created_at, updated_at 
		 FROM accounts WHERE email = $1`,
		email)

	var account domain.AccountDBModel
	err := row.Scan(&account.ID, &account.Type, &account.Email, &account.PasswordHash, &account.FirstName, &account.MiddleName,
		&account.LastName, &account.EmailVerified, &account.CurrentLatitude, &account.CurrentLongitude,
		&account.FCMToken, &account.CreatedAt, &account.UpdatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil // Account not found
		}
		return nil, err
	}

	return &account, nil
}

func (p *postgresAccountsRepository) GetAccountByID(ctx context.Context, accountID int64) (*domain.AccountDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`SELECT id, type, email, password_hash, firstname, middlename, lastname, email_verified,
		        current_latitude, current_longitude, fcm_token, created_at, updated_at 
		 FROM accounts WHERE id = $1`,
		accountID)

	var account domain.AccountDBModel
	err := row.Scan(&account.ID, &account.Type, &account.Email, &account.PasswordHash, &account.FirstName, &account.MiddleName,
		&account.LastName, &account.EmailVerified, &account.CurrentLatitude, &account.CurrentLongitude,
		&account.FCMToken, &account.CreatedAt, &account.UpdatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil // Account not found
		}
		return nil, err
	}

	return &account, nil
}

func (p *postgresAccountsRepository) GetAccountsByType(ctx context.Context, accountType string) ([]*domain.AccountDBModel, error) {
	rows, err := p.conn.Query(ctx,
		`SELECT id, type, email, firstname, middlename, lastname, email_verified,
		        current_latitude, current_longitude, fcm_token, created_at, updated_at 
		 FROM accounts WHERE type = $1`,
		accountType)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var accounts []*domain.AccountDBModel
	for rows.Next() {
		var account domain.AccountDBModel
		err := rows.Scan(&account.ID, &account.Type, &account.Email, &account.FirstName, &account.MiddleName,
			&account.LastName, &account.EmailVerified, &account.CurrentLatitude, &account.CurrentLongitude,
			&account.FCMToken, &account.CreatedAt, &account.UpdatedAt)
		if err != nil {
			return nil, err
		}
		accounts = append(accounts, &account)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return accounts, nil
}
func (p *postgresAccountsRepository) CreateSession(ctx context.Context, id string, secretHash []byte, accountID int64) (*domain.SessionDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`INSERT INTO sessions (id, account_id, secret_hash) 
		 VALUES ($1, $2, $3) 
		 RETURNING id, account_id, secret_hash, created_at`,
		id, accountID, secretHash)

	var session domain.SessionDBModel
	err := row.Scan(&session.ID, &session.AccountID, &session.SecretHash, &session.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &session, nil
}

func (p *postgresAccountsRepository) GetSession(ctx context.Context, sessionID string) (*domain.SessionDBModel, error) {
	row := p.conn.QueryRow(ctx,
		"SELECT id, account_id, secret_hash, created_at FROM sessions WHERE id = $1",
		sessionID)

	var session domain.SessionDBModel
	err := row.Scan(&session.ID, &session.AccountID, &session.SecretHash, &session.CreatedAt)
	if err != nil {
		return nil, nil // Session not found
	}

	return &session, nil
}

func (p *postgresAccountsRepository) DeleteSession(ctx context.Context, sessionID string) error {
	_, err := p.conn.Exec(ctx, "DELETE FROM sessions WHERE id = $1", sessionID)
	return err
}

func (p *postgresAccountsRepository) DeleteAllUserSessions(ctx context.Context, accountID int64) error {
	_, err := p.conn.Exec(ctx, "DELETE FROM sessions WHERE account_id = $1", accountID)
	return err
}

func (p *postgresAccountsRepository) UpdateAccount(ctx context.Context, acc *domain.AccountDBModel) (*domain.AccountDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`UPDATE accounts SET type = $1, email = $2, firstname = $3, middlename = $4, lastname = $5, email_verified = $6, 
		 email_verification_token = $7, email_verification_expires_at = $8, 
		 password_reset_token = $9, password_reset_expires_at = $10,
		 current_latitude = $11, current_longitude = $12, fcm_token = $13
		 WHERE id = $14
		 RETURNING id, type, email, firstname, middlename, lastname, email_verified, 
		           current_latitude, current_longitude, fcm_token, created_at, updated_at`,
		acc.Type, acc.Email, acc.FirstName, acc.MiddleName, acc.LastName, acc.EmailVerified,
		NullString(acc.EmailVerificationToken), NullTime(acc.EmailVerificationExpiresAt),
		NullString(acc.PasswordResetToken), NullTime(acc.PasswordResetExpiresAt),
		NullFloat64(acc.CurrentLatitude), NullFloat64(acc.CurrentLongitude), acc.FCMToken,
		acc.ID)

	var account domain.AccountDBModel
	err := row.Scan(&account.ID, &account.Type, &account.Email, &account.FirstName, &account.MiddleName, &account.LastName,
		&account.EmailVerified, &account.CurrentLatitude, &account.CurrentLongitude, &account.FCMToken,
		&account.CreatedAt, &account.UpdatedAt)
	if err != nil {
		return nil, err
	}

	return &account, nil
}

func (p *postgresAccountsRepository) SetEmailVerificationToken(ctx context.Context, accountID, token string, expiresAt string) error {
	expiresAtTime, err := time.Parse(time.RFC3339, expiresAt)
	if err != nil {
		return err
	}

	_, err = p.conn.Exec(ctx,
		"UPDATE accounts SET email_verification_token = $1, email_verification_expires_at = $2 WHERE id = $3",
		token, expiresAtTime, accountID)
	return err
}

func (p *postgresAccountsRepository) VerifyEmail(ctx context.Context, token string) (*domain.AccountDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`UPDATE accounts SET email_verified = true, email_verification_token = NULL, email_verification_expires_at = NULL
		 WHERE email_verification_token = $1 AND email_verification_expires_at > now()
		 RETURNING id, type, email, firstname, middlename, lastname, email_verified, fcm_token, created_at, updated_at`,
		token)

	var account domain.AccountDBModel
	err := row.Scan(&account.ID, &account.Type, &account.Email, &account.FirstName, &account.MiddleName,
		&account.LastName, &account.EmailVerified, &account.FCMToken, &account.CreatedAt, &account.UpdatedAt)
	if err != nil {
		return nil, err
	}

	return &account, nil
}

func (p *postgresAccountsRepository) SetPasswordResetToken(ctx context.Context, email, token string, expiresAt string) error {
	expiresAtTime, err := time.Parse(time.RFC3339, expiresAt)
	if err != nil {
		return err
	}

	_, err = p.conn.Exec(ctx,
		"UPDATE accounts SET password_reset_token = $1, password_reset_expires_at = $2 WHERE email = $3",
		token, expiresAtTime, email)
	return err
}

func (p *postgresAccountsRepository) ResetPassword(ctx context.Context, token, newPasswordHash string) (*domain.AccountDBModel, error) {
	row := p.conn.QueryRow(ctx,
		`UPDATE accounts SET password_hash = $1, password_reset_token = NULL, password_reset_expires_at = NULL
		 WHERE password_reset_token = $2 AND password_reset_expires_at > now()
		 RETURNING id, type, email, firstname, middlename, lastname, email_verified, fcm_token, created_at, updated_at`,
		newPasswordHash, token)

	var account domain.AccountDBModel
	err := row.Scan(&account.ID, &account.Type, &account.Email, &account.FirstName, &account.MiddleName,
		&account.LastName, &account.EmailVerified, &account.FCMToken, &account.CreatedAt, &account.UpdatedAt)
	if err != nil {
		return nil, err
	}

	return &account, nil
}

func (p *postgresAccountsRepository) ChangePassword(ctx context.Context, accountID int64, newPasswordHash string) error {
	_, err := p.conn.Exec(ctx, "UPDATE accounts SET password_hash = $1 WHERE id = $2",
		newPasswordHash, accountID)
	return err
}

// GetAccountFromSession retrieves the account using the session stored in context
func (p *postgresAccountsRepository) GetAccountFromSession(ctx context.Context) (*domain.AccountDBModel, error) {
	session, ok := GetSessionFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("no session found in context")
	}

	account, err := p.GetAccountByID(ctx, session.AccountID)
	if err != nil {
		return nil, err
	}
	if account == nil {
		return nil, fmt.Errorf("account not found")
	}

	return account, nil
}

func (p *postgresAccountsRepository) ValidateSessionToken(ctx context.Context, token string) (*domain.SessionDBModel, error) {
	// Parse token to get session ID
	// Token format is: id.secret
	parts := strings.Split(token, ".")
	if len(parts) != 2 {
		return nil, nil // Invalid token format
	}

	sessionID := parts[0]
	secret := parts[1]

	// Get session from database
	session, err := p.GetSession(ctx, sessionID)
	if err != nil || session == nil {
		return nil, err
	}

	// Verify the secret hash
	secretHash := sha256.Sum256([]byte(secret))
	if subtle.ConstantTimeCompare(session.SecretHash, secretHash[:]) != 1 {
		return nil, nil // Invalid token
	}

	return session, nil
}

func (p *postgresAccountsRepository) CleanupExpiredSessions(ctx context.Context) error {
	// Delete sessions older than 7 days
	_, err := p.conn.Exec(ctx,
		"DELETE FROM sessions WHERE created_at < NOW() - INTERVAL '7 days'")
	return err
}

func (p *postgresAccountsRepository) AddFavouriteAddress(ctx context.Context, accountID int64, address string) error {
	_, err := p.conn.Exec(ctx,
		"INSERT INTO account_addresses (address_line, account_id) VALUES ($1, $2)",
		address, accountID)
	return err
}

func (p *postgresAccountsRepository) GetFavouriteAddresses(ctx context.Context, accountID int64) ([]string, error) {
	rows, err := p.conn.Query(ctx,
		"SELECT address_line FROM account_addresses WHERE account_id = $1",
		accountID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	addresses := make([]string, 0)
	for rows.Next() {
		var address string
		if err := rows.Scan(&address); err != nil {
			return nil, err
		}
		addresses = append(addresses, address)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return addresses, nil
}

func (p *postgresAccountsRepository) DeleteFavouriteAddress(ctx context.Context, accountID int64, address string) error {
	_, err := p.conn.Exec(ctx,
		"DELETE FROM account_addresses WHERE account_id = $1 AND address_line = $2",
		accountID, address)
	return err
}

func (p *postgresAccountsRepository) RemoveUnverifiedExpiredAccounts(ctx context.Context) (int64, error) {
	tags, err := p.conn.Exec(ctx,
		"DELETE FROM accounts WHERE email_verified = false AND email_verification_expires_at < NOW()")
	if err != nil {
		return 0, err
	}
	return tags.RowsAffected(), nil
}

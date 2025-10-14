package domain

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"math/big"
	"strings"
	"time"

	"golang.org/x/crypto/argon2"
)

type AccountsRepository interface {
	CreateAccount(ctx context.Context, acc *AccountDBModel) (*AccountDBModel, error)
	GetAccountByID(ctx context.Context, accountID int64) (*AccountDBModel, error)
	GetAccountByEmail(ctx context.Context, email string) (*AccountDBModel, error)
	GetAccountsByType(ctx context.Context, accountType string) ([]*AccountDBModel, error)
	UpdateAccount(ctx context.Context, acc *AccountDBModel) (*AccountDBModel, error)
	SetEmailVerificationToken(ctx context.Context, accountID, token string, expiresAt string) error
	VerifyEmail(ctx context.Context, token string) (*AccountDBModel, error)
	SetPasswordResetToken(ctx context.Context, email, token string, expiresAt string) error
	ResetPassword(ctx context.Context, token, newPasswordHash string) (*AccountDBModel, error)
	ChangePassword(ctx context.Context, accountID int64, newPasswordHash string) error
	CreateSession(ctx context.Context, id string, secretHash []byte, accountID int64) (*SessionDBModel, error)
	ValidateSessionToken(ctx context.Context, token string) (*SessionDBModel, error)
	GetSession(ctx context.Context, sessionID string) (*SessionDBModel, error)
	DeleteSession(ctx context.Context, sessionID string) error
	DeleteAllUserSessions(ctx context.Context, accountID int64) error
	CleanupExpiredSessions(ctx context.Context) error
	GetAccountFromSession(ctx context.Context) (*AccountDBModel, error)
	AddFavouriteAddress(ctx context.Context, accountID int64, addressName string, addressLine string) error
	GetFavouriteAddresses(ctx context.Context, accountID int64) ([]AddressDBModel, error)
	DeleteFavouriteAddress(ctx context.Context, accountID int64, addressID int64) error
	RemoveUnverifiedExpiredAccounts(ctx context.Context) (int64, error)
	UpdateLocation(ctx context.Context, accountID int64, lat, lon float64) error
}

const SessionExpiresInSeconds = 7 * 24 * 60 * 60       // 7 days
const EmailVerificationExpiresInSeconds = 24 * 60 * 60 // 24 hours
const PasswordResetExpiresInSeconds = 60 * 60          // 1 hour

type AddressDBModel struct {
	ID          int64
	AddressName string
	AddressLine string
}

type AccountDBModel struct {
	ID                         int64
	Type                       string
	Email                      string
	PasswordHash               string
	FirstName                  string
	MiddleName                 string
	LastName                   string
	EmailVerified              bool
	EmailVerificationToken     string
	EmailVerificationExpiresAt string
	PasswordResetToken         string
	PasswordResetExpiresAt     string
	CurrentLatitude            *float64 // can be nil
	CurrentLongitude           *float64 // can be nil
	FCMToken                   string
	CreatedAt                  string
	UpdatedAt                  string
}

type SessionDBModel struct {
	ID         string
	AccountID  int64
	SecretHash []byte
	CreatedAt  string
}

type SessionDBModelWithToken struct {
	SessionModel *SessionDBModel
	Token        string
}

func HashPassword(password string) (string, error) {
	// Generate a random salt
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		return "", err
	}

	// Hash the password using Argon2id with recommended parameters
	// memory: 19456 KB (19 MB), iterations: 2, parallelism: 1, keyLength: 32
	hash := argon2.IDKey([]byte(password), salt, 2, 19456, 1, 32)

	// Encode the salt and hash as base64 and combine them
	// Format: $argon2id$salt$hash
	saltEncoded := base64.RawStdEncoding.EncodeToString(salt)
	hashEncoded := base64.RawStdEncoding.EncodeToString(hash)

	return fmt.Sprintf("$argon2id$%s$%s", saltEncoded, hashEncoded), nil
}

func CheckPasswordHash(password, storedHash string) bool {
	// Parse the stored hash to extract salt and hash
	parts := strings.Split(storedHash, "$")
	if len(parts) != 4 || parts[0] != "" || parts[1] != "argon2id" {
		return false
	}

	salt, err := base64.RawStdEncoding.DecodeString(parts[2])
	if err != nil {
		return false
	}

	expectedHash, err := base64.RawStdEncoding.DecodeString(parts[3])
	if err != nil {
		return false
	}

	// Hash the provided password with the same salt and parameters
	hash := argon2.IDKey([]byte(password), salt, 2, 19456, 1, 32)

	// Use constant-time comparison to prevent timing attacks
	return subtle.ConstantTimeCompare(hash, expectedHash) == 1
}

func GetCurrentTimeRFC3339() string {
	return time.Now().Format(time.RFC3339)
}

func AddTimeToRFC3339(timeStr string, duration time.Duration) (string, error) {
	t, err := time.Parse(time.RFC3339, timeStr)
	if err != nil {
		return "", err
	}
	return t.Add(duration).Format(time.RFC3339), nil
}

func GenerateSecureToken() (string, error) {
	bytes := make([]byte, 32)
	_, err := rand.Read(bytes)
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

func generateSecureRandomString() string {
	// Human readable alphabet (a-z, 0-9 without l, o, 0, 1 to avoid confusion)
	alphabet := "abcdefghijkmnpqrstuvwxyz23456789"

	// Generate 24 bytes = 192 bits of entropy.
	// We're only going to use 5 bits per byte so the total entropy will be 192 * 5 / 8 = 120 bits
	bytes := make([]byte, 24)
	rand.Read(bytes)

	id := ""
	for i := range bytes {
		// >> 3 "removes" the right-most 3 bits of the byte
		id += string(alphabet[bytes[i]>>3])
	}
	return id
}

func hashSecret(secret string) []byte {
	secretBytes := []byte(secret)
	hash := sha256.Sum256(secretBytes)
	return hash[:]
}

func GenerateSession() (string, string, []byte) {
	id := generateSecureRandomString()
	secret := generateSecureRandomString()
	secretHash := hashSecret(secret)

	token := id + "." + secret

	return id, token, secretHash
}

func GenerateVerificationCode() string {
	code := ""
	for i := 0; i < 6; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			// Fallback in case of error
			return "000000"
		}
		code += n.String()
	}
	return code
}

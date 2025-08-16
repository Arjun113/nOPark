package email

import (
	"fmt"
	"net/smtp"
	"os"
	"strconv"
)

type Service struct {
	host     string
	port     int
	username string
	password string
}

func NewService() *Service {
	port, err := strconv.Atoi(os.Getenv("SMTP_PORT"))
	if err != nil {
		port = 587
	}
	return &Service{
		host:     os.Getenv("SMTP_HOST"),
		port:     port,
		username: os.Getenv("SMTP_USERNAME"),
		password: os.Getenv("SMTP_PASSWORD"),
	}
}

func (s *Service) SendEmailVerification(to, token string) error {
	subject := "Verify your email address"
	body := fmt.Sprintf(`
Hello,

Please use the code below to verify your email address:

%s

This code will expire in 1 hour.

If you didn't create an account, please ignore this email.

Best regards,
nOPark Team
`, token)

	return s.sendEmail(to, subject, body)
}

func (s *Service) SendPasswordReset(to, token string) error {
	subject := "Reset your password"
	body := fmt.Sprintf(`
Hello,

You requested to reset your password. Please use the code below to continue:

%s

This code will expire in 1 hour.

If you didn't request a password reset, please ignore this email.

Best regards,
nOPark Team
`, token)

	return s.sendEmail(to, subject, body)
}

func (s *Service) sendEmail(to, subject, body string) error {
	if os.Getenv("ENV") == "development" {
		fmt.Printf("=== EMAIL ===\nTo: %s\nSubject: %s\nBody:\n%s\n=============\n", to, subject, body)
		return nil
	}

	auth := smtp.PlainAuth("", s.username, s.password, s.host)

	msg := []byte(fmt.Sprintf("To: %s\r\nSubject: %s\r\n\r\n%s\r\n", to, subject, body))

	addr := fmt.Sprintf("%s:%d", s.host, s.port)
	return smtp.SendMail(addr, auth, s.username, []string{to}, msg)
}

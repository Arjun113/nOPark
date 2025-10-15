package email

import (
	"fmt"
)

type Service struct{}

func NewService() *Service {
	return &Service{}
}

func (s *Service) SendEmailVerification(to, token string) error {
	subject := "Verify your email address"
	body := fmt.Sprintf(`
Hello,

Please use the code below to verify your email address:

%s

This code will expire in 24 hours.

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
	// In a real implementation, you would use an email service API here.
	// Due to time constraints, we'll just print the email to the console.
	fmt.Printf("=== EMAIL ===\nTo: %s\nSubject: %s\nBody:\n%s\n=============\n", to, subject, body)
	return nil
}

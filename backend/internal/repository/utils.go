package repository

import "time"

// Helper functions to handle nullable fields
func NullString(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func NullTime(s string) *time.Time {
	if s == "" {
		return nil
	}
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		return nil
	}
	return &t
}

func NullFloat64(f *float64) *float64 {
	if f == nil {
		return nil
	}
	return f
}
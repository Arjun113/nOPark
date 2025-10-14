package utils

import (
	"fmt"
	"net/http"
	"strconv"
)

func StringFromQueryParam(r *http.Request, key string, optional bool) (*string, error) {
	valStr := r.URL.Query().Get(key)
	if valStr == "" {
		if optional {
			return nil, nil
		}
		return nil, fmt.Errorf("%s parameter is required", key)
	}

	return &valStr, nil
}

func FloatFromQueryParam(r *http.Request, key string, optional bool) (*float64, error) {
	valStr, err := StringFromQueryParam(r, key, optional)
	if err != nil || valStr == nil {
		return nil, err
	}

	val, err := strconv.ParseFloat(*valStr, 64)
	if err != nil {
		return nil, fmt.Errorf("invalid %s parameter: %v", key, err)
	}

	return &val, nil
}

func IntFromQueryParam(r *http.Request, key string, optional bool) (*int64, error) {
	valStr, err := StringFromQueryParam(r, key, optional)
	if err != nil || valStr == nil {
		return nil, err
	}

	val, err := strconv.ParseInt(*valStr, 10, 64)
	if err != nil {
		return nil, fmt.Errorf("invalid %s parameter: %v", key, err)
	}

	return &val, nil
}

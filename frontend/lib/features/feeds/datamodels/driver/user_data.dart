class UserResponse {
  final String firstName;
  final String middleName;
  final String lastName;
  final double rating;
  final int ratingCount;

  const UserResponse({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.rating,
    required this.ratingCount
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
        firstName: json['first_name'],
        middleName: json['middle_name'],
        lastName: json['last_name'],
        rating: (json['rating'] ?? 0).toDouble(),
        ratingCount: (json['number_of_ratings']) as int
    );
  }
}

/*
FirstName        string   `json:"first_name"`
	MiddleName       string   `json:"middle_name"`
	LastName         string   `json:"last_name"`
	CurrentLatitude  *float64 `json:"current_latitude"`
	CurrentLongitude *float64 `json:"current_longitude"`
	Rating           *float64 `json:"rating"`
	NumberOfRatings  int64    `json:"number_of_ratings"`
	Reviews          []string `json:"reviews"`
 */
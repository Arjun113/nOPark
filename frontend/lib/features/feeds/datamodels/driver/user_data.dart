class UserResponse {
  final String firstName;
  final String middleName;
  final String lastName;
  final int rating;
  final int ratingCount;

  const UserResponse({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.rating,
    required this.ratingCount,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      rating: (json['rating'] ?? 0).toInt(),
      ratingCount: (json['number_of_ratings']) as int,
    );
  }
}

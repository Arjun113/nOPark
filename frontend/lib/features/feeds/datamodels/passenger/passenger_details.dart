class PassengerDetails {
  final String firstName;
  final String middleName;
  final String lastName;
  final double rating;
  final int numRatings;

  const PassengerDetails({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.numRatings,
    required this.rating
  });

  factory PassengerDetails.fromJson(Map<String, dynamic> json) {
    return PassengerDetails(
        firstName: json['first_name'] as String,
        middleName: json['middle_name'] as String,
        lastName: json['last_name'] as String,
        numRatings: (json['number_of_ratings'] as num?)?.toInt() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0
    );
  }
}
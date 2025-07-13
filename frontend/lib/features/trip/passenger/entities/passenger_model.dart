import '../../entities/user.dart';

class Passenger extends User {
  final double rating;

  Passenger({
    required this.rating,
    required super.dateOfBirth,
    required super.firstName,
    required super.middleName,
    required super.lastName,
    required super.monashEmail,
    required super.imageUrl,
    required super.phoneNumber
});

  factory Passenger.fromJson (Map<String, dynamic> json) {
    final baseUser = User.fromJson(json);
    return Passenger(
      firstName: baseUser.firstName,
      lastName: baseUser.lastName,
      middleName: baseUser.middleName,
      monashEmail: baseUser.monashEmail,
      phoneNumber: baseUser.phoneNumber,
      imageUrl: baseUser.imageUrl,
      dateOfBirth: baseUser.dateOfBirth,
      rating: json['rating']
    );
  }

  @override
  Map<String, dynamic> toJson () {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'imageUrl': imageUrl,
      'dateOfBirth': dateOfBirth.toString(),
      'phoneNumber': phoneNumber,
      'monashEmail': monashEmail,
      'rating': rating
    };
  }
}


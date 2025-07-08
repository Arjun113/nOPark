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

  Map<String, dynamic> toJson () {
    return {
      'firstName': this.firstName,
      'middleName': this.middleName,
      'lastName': this.lastName,
      'imageUrl': this.imageUrl,
      'dateOfBirth': this.dateOfBirth.toString(),
      'phoneNumber': this.phoneNumber,
      'monashEmail': this.monashEmail,
      'rating': this.rating
    };
  }
}


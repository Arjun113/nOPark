import '../../entities/user.dart';

class Passenger extends User {
  final int rating;

  Passenger({
    required this.rating,
    required super.firstName,
    required super.middleName,
    required super.lastName,
    required super.email,
    required super.imageUrl,
    required super.type,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    final baseUser = User.fromJson(json);
    return Passenger(
      firstName: baseUser.firstName,
      lastName: baseUser.lastName,
      middleName: baseUser.middleName,
      email: baseUser.email,
      imageUrl: baseUser.imageUrl,
      rating: json['rating'],
      type: "passenger",
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'imageUrl': imageUrl,
      'email': email,
      'rating': rating,
      'type': type,
    };
  }
}

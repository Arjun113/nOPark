import '../../entities/user.dart';

class Passenger extends User {
  final double rating;

  Passenger({
    required this.rating,
    required super.firstName,
    required super.middleName,
    required super.lastName,
    required super.monashEmail,
    required super.imageUrl,
    required super.token,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    final baseUser = User.fromJson(json);
    return Passenger(
      firstName: baseUser.firstName,
      lastName: baseUser.lastName,
      middleName: baseUser.middleName,
      monashEmail: baseUser.monashEmail,
      imageUrl: baseUser.imageUrl,
      rating: json['rating'],
      token: json['token']
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'imageUrl': imageUrl,
      'monashEmail': monashEmail,
      'rating': rating,
      'token': token
    };
  }
}

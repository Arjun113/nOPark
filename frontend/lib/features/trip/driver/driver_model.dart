import '../entities/user.dart';
import '../../../constants/licensetype.dart';

class Driver extends User {
  final double rating;
  final LicenseType licenseType;

  Driver({
    required this.rating,
    required this.licenseType,
    required super.firstName,
    required super.middleName,
    required super.lastName,
    required super.monashEmail,
    required super.imageUrl,
    required super.token
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    final baseUser = User.fromJson(json);
    return Driver(
      firstName: baseUser.firstName,
      lastName: baseUser.lastName,
      middleName: baseUser.middleName,
      monashEmail: baseUser.monashEmail,
      imageUrl: baseUser.imageUrl,
      licenseType: json['licenseType'],
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
      'licenseType': licenseType,
      'token': token
    };
  }
}

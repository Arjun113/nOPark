import '../../../constants/licensetype.dart';
import '../entities/user.dart';

class Driver extends User {
  final int rating;
  final LicenseType licenseType;

  Driver({
    required this.rating,
    required this.licenseType,
    required super.firstName,
    required super.middleName,
    required super.lastName,
    required super.email,
    required super.type,
    required super.imageUrl,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    final baseUser = User.fromJson(json);
    return Driver(
      firstName: baseUser.firstName,
      lastName: baseUser.lastName,
      middleName: baseUser.middleName,
      email: baseUser.email,
      imageUrl: baseUser.imageUrl,
      type: "driver",
      licenseType: json['licenseType'],
      rating: json['rating'],
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
      'licenseType': licenseType,
    };
  }
}

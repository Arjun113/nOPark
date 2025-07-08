import '../entities/user.dart';
import '../../../constants/licensetype.dart';

class Driver extends User {
  final double rating;
  final LicenseType licenseType;

  Driver ({
    required this.rating,
    required this.licenseType,
    required super.firstName,
    required super.middleName,
    required super.lastName,
    required super.phoneNumber,
    required super.dateOfBirth,
    required super.monashEmail,
    required super.imageUrl
});

  factory Driver.fromJson (Map<String, dynamic> json) {
    final baseUser = User.fromJson(json);
    return Driver(
        firstName: baseUser.firstName,
        lastName: baseUser.lastName,
        middleName: baseUser.middleName,
        monashEmail: baseUser.monashEmail,
        phoneNumber: baseUser.phoneNumber,
        imageUrl: baseUser.imageUrl,
        dateOfBirth: baseUser.dateOfBirth,
        licenseType: json['licenseType'],
        rating: json['rating']
    );
  }

  @override
  Map<String, dynamic> toJson () {
    return {
      'firstName': this.firstName,
      'middleName': this.middleName,
      'lastName': this.lastName,
      'imageUrl': this.imageUrl,
      'dateOfBirth': this.dateOfBirth.toString(),
      'phoneNumber': this.phoneNumber,
      'monashEmail': this.monashEmail,
      'rating': this.rating,
      'licenseType': this.licenseType
    };
  }

}
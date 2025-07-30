import 'dart:io';

import '../../domain/entities/signup_payload.dart';

class SignupModel extends SignupPayload {
  const SignupModel({
    required super.name,
    required super.age,
    required super.monashEmail,
    required super.password,
    required super.phoneNumber,
    required super.role,
    super.profilePicture,
  });

  factory SignupModel.fromJson(Map<String, dynamic> json) {
    return SignupModel(
      name: json['name'],
      age: json['age'],
      monashEmail: json['email'],
      password: json['password'],
      phoneNumber: json['phone'],
      role: json['role'],
      profilePicture: File(json['profilePicturePath']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'age': age.toString(),
      'password': password,
      'monashEmail': monashEmail,
      'profilePicturePath': profilePicture?.path,
    };
  }
}

class VerifyOtpModel {
  final int otp;
  final bool signedUp;

  const VerifyOtpModel({required this.otp, required this.signedUp});

  factory VerifyOtpModel.fromJson(Map<String, dynamic> json) {
    return VerifyOtpModel(
      otp: int.parse(json['otp']),
      signedUp: bool.parse(json['signedUp']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'otp': otp.toString(),
      'signedUp': signedUp.toString(),
    };
  }
}

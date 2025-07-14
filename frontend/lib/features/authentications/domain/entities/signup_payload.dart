import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../../../constants/userRoles.dart';

class SignupPayload extends Equatable {
  final String name;
  final DateTime age;
  final File? profilePicture;
  final String monashEmail;
  final String phoneNumber;
  final Role role;
  final String password;

  SignupPayload ({
    required this.name,
    required this.monashEmail,
    required this.password,
    required this.phoneNumber,
    required this.age,
    required this.role,
    this.profilePicture
  });

  @override
  List<Object?> get props => <Object>[this.name, this.monashEmail, this.phoneNumber, this,age, this.role];
}
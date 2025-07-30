import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../../../constants/user_roles.dart';

class SignupPayload extends Equatable {
  final String name;
  final DateTime age;
  final File? profilePicture;
  final String monashEmail;
  final String phoneNumber;
  final Role role;
  final String password;

  const SignupPayload({
    required this.name,
    required this.monashEmail,
    required this.password,
    required this.phoneNumber,
    required this.age,
    required this.role,
    this.profilePicture,
  });

  @override
  List<Object?> get props => <Object>[
    name,
    monashEmail,
    phoneNumber,
    this,
    age,
    role,
  ];
}

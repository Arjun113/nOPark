import 'package:equatable/equatable.dart';

class LoginPayload extends Equatable {
  final String email;
  final String password;

  LoginPayload({required this.email, required this.password});

  @override
  List<Object?> get props => <Object>[this.email];
}

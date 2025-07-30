import 'package:dartz/dartz.dart';
import '../../datasources/model/signup_model.dart';
import '../entities/signup_payload.dart';
import '../../../../logic/error/failures.dart';

abstract class AuthenticationRepository {
  Future<Either<Failure, String>> login(String emailAddress, String password);

  Future<Either<Failure, String>> signup(SignupPayload newUserCreds);
}

abstract class OTPVerificationRepository {
  Future<Either<Failure, VerifyOtpModel>> verifyOTP(String emailAddress);
}

abstract class UserRepository {
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, void>> setLoggedIn(String emailAddress);
}

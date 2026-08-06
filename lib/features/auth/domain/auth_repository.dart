import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, User>> loginWithGoogle();

  Future<Either<Failure, User>> loginWithApple();

  Future<Either<Failure, Unit>> logout();
}

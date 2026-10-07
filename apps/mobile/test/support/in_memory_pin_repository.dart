import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/security/pin_repository.dart';

class InMemoryPinRepository implements PinRepository {
  InMemoryPinRepository({
    this.currentPin = '123456',
    this.verifyResult,
    this.changeResult,
  });

  String currentPin;
  Either<Failure, bool>? verifyResult;
  Either<Failure, Unit>? changeResult;

  int verifyCallCount = 0;
  int changeCallCount = 0;
  String? lastVerifiedPin;
  String? lastChangedCurrentPin;
  String? lastChangedNewPin;

  @override
  Future<Either<Failure, bool>> verifyPin(String pin) async {
    verifyCallCount++;
    lastVerifiedPin = pin;
    if (verifyResult != null) return verifyResult!;
    return right(pin == currentPin);
  }

  @override
  Future<Either<Failure, Unit>> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    changeCallCount++;
    lastChangedCurrentPin = currentPin;
    lastChangedNewPin = newPin;
    if (changeResult != null) return changeResult!;
    if (currentPin != this.currentPin) {
      return left(const Failure.unauthorized());
    }
    this.currentPin = newPin;
    return right(unit);
  }
}

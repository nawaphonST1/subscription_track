import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';

/// Contract สำหรับการตรวจสอบและจัดการรหัส PIN 6 หลัก
abstract interface class PinRepository {
  /// ตรวจสอบว่า [pin] ที่ส่งเข้ามาถูกต้องหรือไม่
  Future<Either<Failure, bool>> verifyPin(String pin);

  /// เปลี่ยนรหัส PIN จาก [currentPin] เป็น [newPin]
  Future<Either<Failure, Unit>> changePin({
    required String currentPin,
    required String newPin,
  });
}

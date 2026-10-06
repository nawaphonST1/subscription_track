import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    String? name,
    String? securityPin,
  });

  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> loginWithGoogle();

  Future<Either<Failure, User>> loginWithApple();

  /// ดึงผู้ใช้ของ session ปัจจุบัน ใช้ตอนเปิดแอปเพื่อกู้ session คืน
  ///
  /// สัญญาของ [Failure] ที่คืนกลับมา — ผู้เรียกใช้แยกเคสจากตรงนี้:
  /// - [Failure.unauthorized] = **ไม่มี session ที่ใช้ได้** (ไม่มี token เก็บไว้
  ///   หรือ token หมดอายุ/ถูกเพิกถอน) ⇒ ผู้เรียกควรล้าง token ทิ้ง
  /// - [Failure.networkError] = ต่อไม่ติด/หมดเวลา ⇒ **ห้ามล้าง token**
  ///   เพราะ session อาจยังดีอยู่ แค่เน็ตมีปัญหาชั่วคราว
  /// - [Failure.serverError] = ฝั่งเซิร์ฟเวอร์ผิดพลาด ⇒ ห้ามล้าง token เช่นกัน
  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, Unit>> logout();
}

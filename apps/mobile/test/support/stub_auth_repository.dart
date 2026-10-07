import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

/// repository เปล่าสำหรับ widget test
///
/// ตั้งแต่ `AuthNotifier.build()` กู้ session เอง การไม่ override
/// `authRepositoryProvider` จะทำให้ widget test สร้าง `RemoteAuthRepository`
/// ตัวจริง ซึ่งเปิด `http.Client` และไปแตะ `SharedPreferences` ที่ไม่มี plugin
/// ในเทสต์ — เป็น I/O ที่ widget test ไม่ควรทำ และทำให้ผลลัพธ์ไม่แน่นอน
///
/// ตัวนี้ตอบ "ไม่มี session" ทันทีโดยไม่แตะอะไรเลย
class StubAuthRepository implements AuthRepository {
  StubAuthRepository({this.currentUser});

  final User? currentUser;

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    final user = currentUser;
    if (user == null) return left(const Failure.unauthorized());
    return right(user);
  }

  @override
  Future<Either<Failure, Unit>> logout() async => right(unit);

  @override
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  }) async =>
      right(User(id: 'stub-login', email: email));

  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    String? name,
    double? monthlyIncome,
    String? securityPin,
  }) async =>
      right(User(id: 'stub-register', email: email, name: name ?? '', income: monthlyIncome ?? 0.0));

  @override
  Future<Either<Failure, User>> loginWithGoogle() async =>
      right(const User(id: 'stub-google', email: 'google@example.com'));
}

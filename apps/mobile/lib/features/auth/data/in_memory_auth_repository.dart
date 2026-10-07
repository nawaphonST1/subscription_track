import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/utils/logger.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';
import 'package:subscription_track/features/auth/domain/credit_card.dart'; // <-- อย่าลืม import อันนี้

class InMemoryAuthRepository implements AuthRepository {
  User? _currentUser;

  User? get currentUser => _currentUser;

  @override
  Future<Either<Failure, User>> loginWithGoogle() async {
    logger.i('Mock Google login');
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = const User(
      id: 'mock-user-123',
      email: 'user@example.com',
      name: 'John Doe',
      avatar: 'https://i.pravatar.cc/150?img=1',
      authProvider: 'google',
      //income: 35000,
      currency: 'THB',
      pinConfigured: true,
      // เพิ่มข้อมูลบัตรเครดิตจำลองตรงนี้ครับ
      creditCards: [
        CreditCard(
          id: 'card-1',
          bankName: 'KBank',
          last4Digits: '4242',
          creditLimit: 50000.0,
          currentBalance: 12500.0,
          cardColor: '#00A859', // สีเขียว KBank
        ),
        CreditCard(
          id: 'card-2',
          bankName: 'SCB',
          last4Digits: '8888',
          creditLimit: 100000.0,
          currentBalance: 45000.0,
          cardColor: '#4E2A84', // สีม่วง SCB
        ),
      ],
    );

    return right(_currentUser!);
  }


  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    String? name,
    String? securityPin,
  }) async {
    logger.i('Mock Register with Email: $email');
    await Future.delayed(const Duration(seconds: 1));

    // สมมติว่าลงทะเบียนสำเร็จ
    _currentUser = User(
      id: 'mock-email-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name ?? 'New User',
      authProvider: 'email',
      //income: 0, // เริ่มต้นด้วย 0
      currency: 'THB',
      pinConfigured: securityPin != null && securityPin.isNotEmpty,
      creditCards: [], // เริ่มต้นไม่มีบัตร
    );

    return right(_currentUser!);
  }

  @override
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    logger.i('Mock Login with Email: $email');
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = User(
      id: 'mock-email-user-login',
      email: email,
      name: email.split('@').first,
      authProvider: 'email',
      currency: 'THB',
      pinConfigured: true,
      creditCards: const [
        CreditCard(
          id: 'card-1',
          bankName: 'KBank',
          last4Digits: '4242',
          creditLimit: 50000.0,
          currentBalance: 12500.0,
          cardColor: '#00A859',
        ),
      ],
    );

    return right(_currentUser!);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    final user = _currentUser;
    if (user == null) return left(const Failure.unauthorized());
    return right(user);
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    logger.i('Logout');
    _currentUser = null;
    return right(unit);
  }
}
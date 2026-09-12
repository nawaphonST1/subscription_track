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
          currentBalance: 8500.0,
          cardColor: '#4E2A84', // สีม่วง SCB
        ),
      ],
    );

    return right(_currentUser!);
  }

  @override
  Future<Either<Failure, User>> loginWithApple() async {
    logger.i('Mock Apple login');
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = const User(
      id: 'mock-user-456',
      email: 'user@icloud.com',
      name: 'Jane Doe',
      avatar: 'https://i.pravatar.cc/150?img=5',
      authProvider: 'apple',
      //income: 45000,
      currency: 'THB',
      creditCards: [
        CreditCard(
          id: 'card-3',
          bankName: 'UOB',
          last4Digits: '1234',
          creditLimit: 80000.0,
          currentBalance: 20000.0,
          cardColor: '#002B5E', // สีน้ำเงิน UOB
        ),
      ],
    );

    return right(_currentUser!);
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    logger.i('Logout');
    _currentUser = null;
    return right(unit);
  }
}
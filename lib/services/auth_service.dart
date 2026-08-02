import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/utils/logger.dart';
import 'package:subscription_track/models/user.dart';

class AuthService {
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<Either<Failure, User>> loginWithGoogle() async {
    logger.i('Mock Google login');
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = const User(
      id: 'mock-user-123',
      email: 'user@example.com',
      name: 'John Doe',
      avatar: 'https://i.pravatar.cc/150?img=1',
      authProvider: 'google',
      income: 35000,
      currency: 'THB',
    );
    
    return right(_currentUser!);
  }

  Future<Either<Failure, User>> loginWithApple() async {
    logger.i('Mock Apple login');
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = const User(
      id: 'mock-user-456',
      email: 'user@icloud.com',
      name: 'Jane Doe',
      avatar: 'https://i.pravatar.cc/150?img=5',
      authProvider: 'apple',
      income: 35000,
      currency: 'THB',
    );
    
    return right(_currentUser!);
  }

  Future<Either<Failure, Unit>> logout() async {
    logger.i('Logout');
    _currentUser = null;
    return right(unit);
  }
}

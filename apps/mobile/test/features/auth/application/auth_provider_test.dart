import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

void main() {
  test('auth controller delegates login and logout to repository', () async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(authProvider.notifier);

    await controller.loginWithGoogle();
    expect(container.read(authProvider).value?.id, 'test-user');
    expect(repository.googleLoginCalls, 1);

    await controller.logout();
    expect(container.read(authProvider).value, isNull);
    expect(repository.logoutCalls, 1);
  });
}

class _FakeAuthRepository implements AuthRepository {
  int googleLoginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<Either<Failure, User>> loginWithGoogle() async {
    googleLoginCalls++;
    return right(const User(id: 'test-user', email: 'test@example.com'));
  }

  @override
  Future<Either<Failure, User>> loginWithApple() async {
    return right(const User(id: 'apple-user', email: 'apple@example.com'));
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    logoutCalls++;
    return right(unit);
  }
}

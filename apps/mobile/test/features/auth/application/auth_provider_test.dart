import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/data/in_memory_auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

void main() {
  test('auth controller delegates login and logout to repository', () async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(authProvider, (_, __) {});
    addTearDown(sub.close);
    final controller = container.read(authProvider.notifier);

    // build() กู้ session เองแบบ async — รอให้จบก่อน ไม่งั้นผลของมัน
    // (fake ตอบ unauthorized ⇒ เรียก logout เพื่อล้าง token) จะมาแทรกกลางเทสต์
    for (var i = 0; i < 100 && container.read(authProvider).isLoading; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final logoutsAfterRestore = repository.logoutCalls;

    await controller.loginWithGoogle();
    expect(container.read(authProvider).value?.id, 'test-user');
    expect(repository.googleLoginCalls, 1);

    await controller.logout();
    expect(container.read(authProvider).value, isNull);
    expect(repository.logoutCalls, logoutsAfterRestore + 1);

    await controller.loginWithEmail(
      email: 'existing@example.com',
      password: 'password123',
    );
    expect(container.read(authProvider).value?.email, 'existing@example.com');
    expect(repository.emailLoginCalls, 1);

    await controller.registerWithEmail(
      email: 'newuser@example.com',
      password: 'password123',
      name: 'New User',
    );
    expect(container.read(authProvider).value?.email, 'newuser@example.com');
    expect(repository.registerCalls, 1);
  });

  test('real InMemoryAuthRepository registration flow returns complete User model', () async {
    final realRepo = InMemoryAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(realRepo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(authProvider, (_, __) {});
    addTearDown(sub.close);
    final notifier = container.read(authProvider.notifier);

    // 1. ทดสอบสมัครสมาชิกด้วย Email
    await notifier.registerWithEmail(
      email: 'somchai.dev@example.com',
      password: 'SecurePassword123!',
      name: 'สมชาย ใจดี',
    );

    final registeredUser = container.read(authProvider).value;
    expect(registeredUser, isNotNull);
    expect(registeredUser?.email, 'somchai.dev@example.com');
    expect(registeredUser?.name, 'สมชาย ใจดี');
    expect(registeredUser?.authProvider, 'email');
    expect(registeredUser?.currency, 'THB');

    // พิมพ์ผลลัพธ์เพื่อแสดงให้ผู้ใช้เห็น
    // ignore: avoid_print
    print('\n======================================================');
    // ignore: avoid_print
    print('🎉 [ผลลัพธ์การสมัครสมาชิกด้วย Email สำเร็จ]');
    // ignore: avoid_print
    print('  - User ID       : ${registeredUser?.id}');
    // ignore: avoid_print
    print('  - Email         : ${registeredUser?.email}');
    // ignore: avoid_print
    print('  - Name          : ${registeredUser?.name}');
    // ignore: avoid_print
    print('  - Auth Provider : ${registeredUser?.authProvider}');
    // ignore: avoid_print
    print('  - Currency      : ${registeredUser?.currency}');
    // ignore: avoid_print
    print('  - Credit Cards  : ${registeredUser?.creditCards.length} ใบ (ผู้ใช้ใหม่)');
    // ignore: avoid_print
    print('  - Auth State    : AsyncData<User> -> นำทางไปหน้า Dashboard อัตโนมัติ');
    // ignore: avoid_print
    print('======================================================\n');

    // 2. ทดสอบสมัคร/เชื่อมต่อด้วย Google (Social Auth Mockup)
    await notifier.loginWithGoogle();
    final googleUser = container.read(authProvider).value;
    expect(googleUser?.authProvider, 'google');

    // ignore: avoid_print
    print('======================================================');
    // ignore: avoid_print
    print('🎉 [ผลลัพธ์การเชื่อมต่อด้วย Google ID สำเร็จ]');
    // ignore: avoid_print
    print('  - User ID       : ${googleUser?.id}');
    // ignore: avoid_print
    print('  - Email         : ${googleUser?.email}');
    // ignore: avoid_print
    print('  - Name          : ${googleUser?.name}');
    // ignore: avoid_print
    print('  - Auth Provider : ${googleUser?.authProvider}');
    // ignore: avoid_print
    print('  - Avatar        : ${googleUser?.avatar}');
    // ignore: avoid_print
    print('  - Cards Loaded  : ${googleUser?.creditCards.length} ใบ');
    // ignore: avoid_print
    print('======================================================\n');

    // 3. ทดสอบสมัคร/เชื่อมต่อด้วย Apple (Social Auth Mockup)
    await notifier.loginWithApple();
    final appleUser = container.read(authProvider).value;
    expect(appleUser?.authProvider, 'apple');

    // ignore: avoid_print
    print('======================================================');
    // ignore: avoid_print
    print('🎉 [ผลลัพธ์การเชื่อมต่อด้วย Apple ID สำเร็จ]');
    // ignore: avoid_print
    print('  - User ID       : ${appleUser?.id}');
    // ignore: avoid_print
    print('  - Email         : ${appleUser?.email}');
    // ignore: avoid_print
    print('  - Name          : ${appleUser?.name}');
    // ignore: avoid_print
    print('  - Auth Provider : ${appleUser?.authProvider}');
    // ignore: avoid_print
    print('  - Avatar        : ${appleUser?.avatar}');
    // ignore: avoid_print
    print('  - Cards Loaded  : ${appleUser?.creditCards.length} ใบ');
    // ignore: avoid_print
    print('======================================================\n');
  });
}

class _FakeAuthRepository implements AuthRepository {
  int googleLoginCalls = 0;
  int logoutCalls = 0;
  int registerCalls = 0;
  int emailLoginCalls = 0;
  int getCurrentUserCalls = 0;

  @override
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emailLoginCalls++;
    return right(User(id: 'login-user', email: email));
  }

  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    String? name,
    String? securityPin,
  }) async {
    registerCalls++;
    return right(User(id: 'new-user', email: email, name: name ?? ''));
  }

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
  Future<Either<Failure, User>> getCurrentUser() async {
    getCurrentUserCalls++;
    return left(const Failure.unauthorized());
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    logoutCalls++;
    return right(unit);
  }
}

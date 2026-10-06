import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/app/application/app_flow_provider.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

/// repository ที่ควบคุมผลของ getCurrentUser ได้ และนับว่า logout ถูกเรียกกี่ครั้ง
///
/// การนับ logout สำคัญ: มันคือตัวชี้ว่า token ถูกล้างหรือไม่ ซึ่งคือเส้นแบ่ง
/// ระหว่าง "token หมดอายุ" กับ "เน็ตมีปัญหา"
class _RestoreRepository implements AuthRepository {
  _RestoreRepository(this._result, {this.delay = Duration.zero});

  final Either<Failure, User> _result;
  final Duration delay;

  int getCurrentUserCalls = 0;
  int logoutCalls = 0;

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    getCurrentUserCalls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return _result;
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    logoutCalls++;
    return right(unit);
  }

  @override
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  }) async =>
      right(User(id: 'login-user', email: email));

  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    String? name,
    String? securityPin,
  }) async =>
      right(User(id: 'new-user', email: email));

  @override
  Future<Either<Failure, User>> loginWithGoogle() async =>
      right(const User(id: 'g', email: 'g@example.com'));

  @override
  Future<Either<Failure, User>> loginWithApple() async =>
      right(const User(id: 'a', email: 'a@example.com'));
}

/// รอให้การกู้ session อัตโนมัติที่ `build()` ยิงไว้ทำงานจนจบ
///
/// ตรงกับของจริงตอนเปิดแอปมากกว่าการเรียก retryRestore() เอง — และสำคัญต่อ
/// การนับ logoutCalls ให้ถูก เพราะ build() กู้ session ให้รอบหนึ่งอยู่แล้ว
Future<void> _settle(
  ProviderContainer container, {
  Duration step = Duration.zero,
  int maxIterations = 200,
}) async {
  for (var i = 0;
      i < maxIterations && container.read(authProvider).isLoading;
      i++) {
    await Future<void>.delayed(step);
  }
}

ProviderContainer _containerWith(_RestoreRepository repository) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  final sub = container.listen(authProvider, (_, __) {});
  addTearDown(sub.close);
  return container;
}

const _restoredUser = User(
  id: 'user-uuid',
  email: 'user@example.com',
  name: 'Restored User',
);

void main() {
  group('กู้ session ตอนเปิดแอป', () {
    test('เริ่มต้นเป็น loading ทันที (splash ขึ้นก่อน)', () {
      final repository = _RestoreRepository(
        right(_restoredUser),
        delay: const Duration(milliseconds: 50),
      );
      final container = _containerWith(repository);

      expect(container.read(authProvider).isLoading, isTrue);
      expect(container.read(authProvider).value, isNull);
    });

    test('มี session ใช้ได้ → data(user) และไม่ล้าง token', () async {
      final repository = _RestoreRepository(right(_restoredUser));
      final container = _containerWith(repository);

      container.listen(authProvider, (_, __) {});
      await _settle(container);

      final state = container.read(authProvider);
      expect(state.value?.id, 'user-uuid');
      expect(repository.getCurrentUserCalls, 1);
      expect(state.hasError, isFalse);
      expect(state.isLoading, isFalse);
      expect(repository.logoutCalls, 0);
    });

    test('ไม่มี token / token หมดอายุ (401) → data(null) และล้าง token', () async {
      final repository = _RestoreRepository(left(const Failure.unauthorized()));
      final container = _containerWith(repository);

      container.listen(authProvider, (_, __) {});
      await _settle(container);

      final state = container.read(authProvider);
      expect(state.value, isNull);
      expect(state.isLoading, isFalse);
      expect(
        state.hasError,
        isFalse,
        reason: '"ยังไม่ได้ login" เป็นสถานะปกติ ไม่ใช่ error',
      );
      expect(
        repository.logoutCalls,
        1,
        reason: 'token ที่ตายแล้วต้องถูกล้าง ไม่งั้นจะถูกแบกไปทุก request',
      );
    });

    test('เน็ตมีปัญหา → error state และ **ไม่** ล้าง token', () async {
      final repository = _RestoreRepository(left(const Failure.networkError()));
      final container = _containerWith(repository);

      container.listen(authProvider, (_, __) {});
      await _settle(container);

      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      expect(state.value, isNull);
      expect(state.isLoading, isFalse, reason: 'ต้องเป็น terminal state ไม่งั้น splash ค้าง');
      expect(
        repository.logoutCalls,
        0,
        reason: 'เน็ตล่มชั่วคราวต้องไม่เตะผู้ใช้ออกจากระบบ token ยังอาจดีอยู่',
      );
      expect(
        (state.error as Failure).displayMessage,
        'ไม่สามารถเชื่อมต่อเครือข่ายได้',
      );
    });

    test('เซิร์ฟเวอร์พัง (500) → error state และไม่ล้าง token', () async {
      final repository =
          _RestoreRepository(left(const Failure.serverError('พังจ้า')));
      final container = _containerWith(repository);

      container.listen(authProvider, (_, __) {});
      await _settle(container);

      expect(container.read(authProvider).hasError, isTrue);
      expect(repository.logoutCalls, 0);
    });

    test('getCurrentUser ที่แขวนเกิน timeout → networkError ไม่ค้างที่ loading',
        () async {
      final repository = _RestoreRepository(
        right(_restoredUser),
        delay: AuthNotifier.sessionRestoreTimeout + const Duration(seconds: 2),
      );
      final container = _containerWith(repository);

      container.listen(authProvider, (_, __) {});

      // เคสนี้ต้องรอเวลาจริงให้ .timeout() ทำงาน ไม่ใช่แค่หมุน microtask
      await _settle(
        container,
        step: const Duration(milliseconds: 50),
        maxIterations: 400,
      );

      final state = container.read(authProvider);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isTrue);
      expect(
        repository.logoutCalls,
        0,
        reason: 'หมดเวลา = ปัญหาเครือข่าย ไม่ใช่ token เสีย',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('retryRestore กลับไป loading ก่อน แล้วเรียก repository ซ้ำ', () async {
      final repository = _RestoreRepository(right(_restoredUser));
      final container = _containerWith(repository);

      container.listen(authProvider, (_, __) {});
      await _settle(container);
      final afterFirst = repository.getCurrentUserCalls;

      await container.read(authProvider.notifier).retryRestore();

      expect(repository.getCurrentUserCalls, afterFirst + 1);
      expect(container.read(authProvider).value?.id, 'user-uuid');
    });
  });

  group('appFlowProvider สะท้อนสถานะ restore ถูกต้อง', () {
    test('loading → isInitializing true, isAuthenticated false', () {
      final repository = _RestoreRepository(
        right(_restoredUser),
        delay: const Duration(milliseconds: 50),
      );
      final container = _containerWith(repository);

      final flow = container.read(appFlowProvider);
      expect(flow.isInitializing, isTrue);
      expect(flow.isAuthenticated, isFalse);
    });

    test('กู้สำเร็จ → isInitializing false, isAuthenticated true', () async {
      final repository = _RestoreRepository(right(_restoredUser));
      final container = _containerWith(repository);

      container.listen(authProvider, (_, __) {});
      await _settle(container);

      final flow = container.read(appFlowProvider);
      expect(flow.isInitializing, isFalse);
      expect(flow.isAuthenticated, isTrue);
    });

    test('401 → isInitializing false, isAuthenticated false', () async {
      final repository = _RestoreRepository(left(const Failure.unauthorized()));
      final container = _containerWith(repository);

      container.listen(authProvider, (_, __) {});
      await _settle(container);

      final flow = container.read(appFlowProvider);
      expect(flow.isInitializing, isFalse);
      expect(flow.isAuthenticated, isFalse);
    });

    test('เน็ตพัง → ยัง terminal (splash ไม่ค้าง) และยังไม่ถือว่า login', () async {
      final repository = _RestoreRepository(left(const Failure.networkError()));
      final container = _containerWith(repository);

      container.listen(authProvider, (_, __) {});
      await _settle(container);

      final flow = container.read(appFlowProvider);
      expect(
        flow.isInitializing,
        isFalse,
        reason: 'ถ้ายัง true อยู่ แอปจริงจะค้างที่ splash ตลอดไป',
      );
      expect(flow.isAuthenticated, isFalse);
    });
  });
}

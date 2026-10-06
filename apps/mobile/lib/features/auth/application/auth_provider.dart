import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

import 'package:http/http.dart' as http;
import 'package:subscription_track/core/network/authenticated_http_client.dart';

part 'auth_provider.g.dart';

final innerHttpClientProvider = Provider<http.Client?>((ref) => null);

final authenticatedHttpClientProvider = Provider<AuthenticatedHttpClient>(
  (ref) => AuthenticatedHttpClient(
    readToken: RemoteAuthRepository.readStoredAuthToken,
    inner: ref.watch(innerHttpClientProvider),
    onUnauthorized: () => ref.read(authProvider.notifier).handleSessionExpired(),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => RemoteAuthRepository(
    client: ref.watch(authenticatedHttpClientProvider),
  ),
);

@riverpod
class AuthNotifier extends _$AuthNotifier {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// เพดานเวลาของการกู้ session ตอนเปิดแอป
  ///
  /// กันหน้า splash ค้างตลอดกาลเมื่อเปิดแอปตอนไม่มีเน็ตแต่มี token ค้างอยู่ —
  /// `http` ไม่มี timeout ในตัว request อาจแขวนยาวจนผู้ใช้คิดว่าแอปค้าง
  static const Duration sessionRestoreTimeout = Duration(seconds: 8);

  /// เริ่มที่ loading แล้วกู้ session แบบ async
  ///
  /// `build()` ต้องเป็น sync เพราะ notifier ตัวนี้เป็น `Notifier<AsyncValue<User?>>`
  /// (ดู `auth_provider.g.dart`) ไม่ใช่ `AsyncNotifier` — การคืน loading แล้วยิง
  /// งาน async ต่อ ทำให้ consumer ทั้ง 8 จุดที่อ่าน `.value`/`.isLoading`
  /// ไม่ต้องแก้อะไรเลย
  Timer? _restoreTimeoutTimer;

  @override
  AsyncValue<User?> build() {
    // ยกเลิก timer ที่ยังค้างเมื่อ provider ถูกทิ้ง ไม่งั้นมันจะอยู่ต่อหลังจอถูก
    // ปิดไปแล้ว และใน widget test จะทำให้ binding ฟ้อง "pending timers"
    ref.onDispose(() {
      _restoreTimeoutTimer?.cancel();
      _restoreTimeoutTimer = null;
    });
    unawaited(_restoreSession());
    return const AsyncValue.loading();
  }

  /// กู้ session จาก token ที่เก็บไว้
  ///
  /// แยก 401 ออกจากปัญหาเครือข่ายอย่างเคร่งครัด: **เฉพาะ**
  /// [Failure.unauthorized] เท่านั้นที่ล้าง token ทิ้ง เน็ตล่มหรือเซิร์ฟเวอร์
  /// พังต้องไม่เตะผู้ใช้ออกจากระบบเงียบ ๆ ทั้งที่ token ยังใช้ได้
  Future<void> _restoreSession() async {
    // จับ reference ไว้ตั้งแต่ก่อน await ครั้งแรก: `_repository` เป็น getter ที่
    // เรียก `ref.read` ซึ่งจะ throw ถ้า provider ถูก dispose ไปแล้วระหว่างที่
    // งาน async ยังค้างอยู่ (เกิดได้จริงเมื่อจอที่ watch อยู่ถูกปิดกลางคัน)
    final repository = _repository;

    // ใช้ Completer + Timer ที่ถือ reference ไว้ แทน Future.timeout เพราะ
    // Future.timeout ไม่เปิดทางให้ยกเลิก timer จากภายนอก — timer 8 วินาทีจะ
    // ค้างอยู่จนกว่าจะครบเวลา แม้ provider ถูกทิ้งไปแล้ว
    final completer = Completer<Either<Failure, User>>();

    _restoreTimeoutTimer?.cancel();
    _restoreTimeoutTimer = Timer(sessionRestoreTimeout, () {
      if (!completer.isCompleted) {
        completer.complete(left(const Failure.networkError()));
      }
    });

    unawaited(
      repository.getCurrentUser().then(
        (value) {
          if (!completer.isCompleted) completer.complete(value);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) {
            completer.complete(left(const Failure.networkError()));
          }
        },
      ),
    );

    final result = await completer.future;
    _restoreTimeoutTimer?.cancel();
    _restoreTimeoutTimer = null;

    if (!ref.mounted) return;

    await result.fold<Future<void>>(
      (failure) async {
        final isExpiredSession = failure == const Failure.unauthorized();
        if (!isExpiredSession) {
          // เก็บ token ไว้ให้ลองใหม่ได้ และพก failure ไปด้วยเพื่อให้ UI
          // แยกออกว่า "ยังไม่ได้ login" ต่างจาก "ต่อเน็ตไม่ได้"
          if (ref.mounted) {
            state = AsyncValue.error(failure, StackTrace.current);
          }
          return;
        }

        // ไม่มี session ที่ใช้ได้ ⇒ ล้าง token ค้างทิ้ง ไม่งั้นทุก request
        // หลังจากนี้จะแบก token ที่ตายแล้วไปด้วย
        await repository.logout();
        if (ref.mounted) state = const AsyncValue.data(null);
      },
      (user) async {
        if (ref.mounted) state = AsyncValue.data(user);
      },
    );
  }

  /// ให้ UI สั่งกู้ session ใหม่ได้หลังเจอปัญหาเครือข่าย
  Future<void> retryRestore() async {
    state = const AsyncValue.loading();
    await _restoreSession();
  }

  /// จัดการกรณี session หมดอายุระหว่างใช้งาน (สัญญาณ 401 จาก [AuthenticatedHttpClient])
  ///
  /// ต่างจาก [logout]:
  /// 1. **ไม่ตั้ง state เป็น loading ก่อน** เพื่อกันหน้าจอวูบกลับไปที่ splash ชั่วขณะ
  /// 2. **เป็น idempotent**: ปลอดภัยเมื่อมี request พร้อมกันหลายตัวเจอปัญหา 401 ในเวลาเดียวกัน
  /// 3. ล้าง token ผ่าน repository และเปลี่ยนสถานะเป็น [AsyncValue.data(null)]
  bool _isHandlingSessionExpired = false;

  Future<void> handleSessionExpired() async {
    if (_isHandlingSessionExpired) return;
    _isHandlingSessionExpired = true;
    try {
      final repository = _repository;
      await repository.logout();
      if (ref.mounted) {
        state = const AsyncValue.data(null);
      }
    } finally {
      _isHandlingSessionExpired = false;
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.loginWithEmail(
      email: email,
      password: password,
    );
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _repository.loginWithGoogle();
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> loginWithApple() async {
    state = const AsyncValue.loading();
    final result = await _repository.loginWithApple();
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? name,
    String? securityPin,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.registerWithEmail(
      email: email,
      password: password,
      name: name,
      securityPin: securityPin,
    );
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final result = await _repository.logout();
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  /// อัปเดตสถานะ pinConfigured ให้เป็น true ใน state หลังตั้งค่า PIN สำเร็จ
  void markPinConfigured() {
    state.whenData((user) {
      if (user != null) {
        state = AsyncValue.data(user.copyWith(pinConfigured: true));
      }
    });
  }
}

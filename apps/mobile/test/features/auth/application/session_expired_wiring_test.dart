import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

const _baseUrl = 'http://localhost:3000';
const _token = 'active-jwt-token';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': _token});
  });

  group('wiring ของ onUnauthorized กับ AuthNotifier', () {
    test('circular dependency guard: provider graph เริ่มต้นได้โดยไม่ throw', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => RemoteAuthRepository(
                baseUrl: _baseUrl,
                client: MockClient((_) async => http.Response('{}', 200)),
                onUnauthorized: () =>
                    ref.read(authProvider.notifier).handleSessionExpired(),
              )),
        ],
      );
      addTearDown(container.dispose);

      // ยืนยันว่าการสร้าง graph ทั้งสองฝั่งพร้อมกันไม่ติด circular dependency loop
      expect(() => container.read(authRepositoryProvider), returnsNormally);
      expect(() => container.read(authProvider), returnsNormally);
    });

    test(
        '401 จาก authenticated endpoint เปลี่ยน state ของ authProvider เป็น data(null) และล้าง token',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/users/me') {
          return http.Response(
            jsonEncode({
              'success': false,
              'statusCode': 401,
              'message': 'Unauthorized',
            }),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      late final RemoteAuthRepository repository;
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) {
            repository = RemoteAuthRepository(
              baseUrl: _baseUrl,
              client: mockClient,
              onUnauthorized: () =>
                  ref.read(authProvider.notifier).handleSessionExpired(),
            );
            return repository;
          }),
        ],
      );
      addTearDown(container.dispose);

      final listenerStates = <AsyncValue<User?>>[];
      final sub = container.listen(authProvider, (_, next) {
        listenerStates.add(next);
      }, fireImmediately: false);
      addTearDown(sub.close);

      // จำลองว่าผู้ใช้ login อยู่แล้ว
      // รอให้ build() settle ก่อน
      for (var i = 0; i < 50 && container.read(authProvider).isLoading; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      // ตรวจสอบว่า SharedPreferences มี token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token);

      // ยิง authenticated request ที่ได้ 401
      listenerStates.clear();
      final result = await repository.getCurrentUser();
      expect(result.isLeft(), isTrue);

      // รอ microtask ให้ callback onUnauthorized ทำงาน
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final finalState = container.read(authProvider);
      expect(finalState.value, isNull);
      expect(finalState.isLoading, isFalse);
      expect(finalState.hasError, isFalse);

      // ยืนยันว่า token ใน SharedPreferences ถูกล้างออกไปจริง
      expect(prefs.getString('auth_token'), isNull);

      // ยืนยันว่า handleSessionExpired ไม่ย้อนกลับไป loading (ไม่วูบ splash)
      expect(listenerStates.any((s) => s.isLoading), isFalse,
          reason: 'handleSessionExpired ต้องไม่กระพริบกลับไป loading กลาง session');
    });

    test('401 จาก /auth/login (รหัสผ่านผิด) ไม่ทริกเกอร์ handleSessionExpired',
        () async {
      var onUnauthorizedFired = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/login') {
          return http.Response(
            jsonEncode({
              'success': false,
              'statusCode': 401,
              'message': 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
            }),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      final repository = RemoteAuthRepository(
        baseUrl: _baseUrl,
        client: mockClient,
        onUnauthorized: () => onUnauthorizedFired++,
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(authProvider, (_, __) {});
      addTearDown(sub.close);

      // พยายาม login ด้วยรหัสผ่านผิด
      await container.read(authProvider.notifier).loginWithEmail(
            email: 'wrong@example.com',
            password: 'wrong-password',
          );

      expect(onUnauthorizedFired, 0,
          reason: 'public path เช่น /auth/login ต้องไม่ยิง onUnauthorized');
      expect(container.read(authProvider).hasError, isTrue);
    });

    test('handleSessionExpired เป็น idempotent เมื่อถูกเรียกซ้ำพร้อมกัน', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => RemoteAuthRepository(
                baseUrl: _baseUrl,
                client: MockClient((_) async => http.Response('{}', 200)),
                onUnauthorized: () =>
                    ref.read(authProvider.notifier).handleSessionExpired(),
              )),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      // เรียกพร้อมกัน 2 ครั้งเพื่อจำลอง 2 in-flight requests 401 พร้อมกัน
      await Future.wait([
        notifier.handleSessionExpired(),
        notifier.handleSessionExpired(),
      ]);

      expect(container.read(authProvider).value, isNull);
    });
  });
}

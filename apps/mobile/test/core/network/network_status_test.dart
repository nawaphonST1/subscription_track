import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/internet_checker.dart';
import 'package:subscription_track/core/network/network_status.dart';

class _FakeInternetChecker implements InternetChecker {
  _FakeInternetChecker({this.hasInternetValue = true});
  bool hasInternetValue;

  @override
  Future<bool> hasInternet() async => hasInternetValue;
}

http.Response _jsonResponse(Map<String, dynamic> body, int statusCode) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  group('NetworkStatusNotifier — checkStatus', () {
    test('สถานะ online เมื่อ /health ตอบกลับ 200 และ status ok', () async {
      final mockClient = MockClient((request) async {
        return _jsonResponse({'status': 'ok', 'checks': {'database': 'ok'}}, 200);
      });

      final container = ProviderContainer(
        overrides: [
          networkClientProvider.overrideWithValue(mockClient),
          internetCheckerProvider.overrideWithValue(_FakeInternetChecker(hasInternetValue: true)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      await notifier.checkStatus();

      final state = container.read(networkStatusProvider);
      expect(state.status, NetworkStatus.online);
      expect(state.isOnline, isTrue);
      expect(state.hasIssue, isFalse);
    });

    test('สถานะ serverMaintenance เมื่อ /health ตอบกลับ 200 แต่ระบุ status maintenance', () async {
      final mockClient = MockClient((request) async {
        return _jsonResponse({
          'status': 'maintenance',
          'checks': {'database': 'ok', 'maintenance': true},
        }, 200);
      });

      final container = ProviderContainer(
        overrides: [
          networkClientProvider.overrideWithValue(mockClient),
          internetCheckerProvider.overrideWithValue(_FakeInternetChecker(hasInternetValue: true)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      await notifier.checkStatus();

      final state = container.read(networkStatusProvider);
      expect(state.status, NetworkStatus.serverMaintenance);
      expect(state.isMaintenance, isTrue);
      expect(state.message, contains('ปิดปรับปรุง'));
    });

    test('สถานะ serverMaintenance เมื่อ /health ตอบกลับ HTTP 503', () async {
      final mockClient = MockClient((request) async {
        return _jsonResponse({
          'statusCode': 503,
          'message': 'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง',
        }, 503);
      });

      final container = ProviderContainer(
        overrides: [
          networkClientProvider.overrideWithValue(mockClient),
          internetCheckerProvider.overrideWithValue(_FakeInternetChecker(hasInternetValue: true)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      await notifier.checkStatus();

      final state = container.read(networkStatusProvider);
      expect(state.status, NetworkStatus.serverMaintenance);
      expect(state.isMaintenance, isTrue);
    });

    test('สถานะ noInternet เมื่อยิงไม่ผ่านและอุปกรณ์ไม่มีสัญญาณอินเทอร์เน็ต', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network is unreachable');
      });

      final fakeChecker = _FakeInternetChecker(hasInternetValue: false);

      final container = ProviderContainer(
        overrides: [
          networkClientProvider.overrideWithValue(mockClient),
          internetCheckerProvider.overrideWithValue(fakeChecker),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      await notifier.checkStatus();

      final state = container.read(networkStatusProvider);
      expect(state.status, NetworkStatus.noInternet);
      expect(state.isNoInternet, isTrue);
      expect(state.message, contains('ไม่มีการเชื่อมต่ออินเทอร์เน็ต'));
    });

    test('สถานะ serverUnreachable เมื่อยิงไม่ผ่านแต่อินเทอร์เน็ตใช้งานได้ปกติ', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final fakeChecker = _FakeInternetChecker(hasInternetValue: true);

      final container = ProviderContainer(
        overrides: [
          networkClientProvider.overrideWithValue(mockClient),
          internetCheckerProvider.overrideWithValue(fakeChecker),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      await notifier.checkStatus();

      final state = container.read(networkStatusProvider);
      expect(state.status, NetworkStatus.serverUnreachable);
      expect(state.isServerUnreachable, isTrue);
      expect(state.message, contains('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'));
    });

    test('สถานะ serverUnreachable เมื่อ server ตอบกลับ 502 Bad Gateway', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Bad Gateway', 502);
      });

      final container = ProviderContainer(
        overrides: [
          networkClientProvider.overrideWithValue(mockClient),
          internetCheckerProvider.overrideWithValue(_FakeInternetChecker(hasInternetValue: true)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      await notifier.checkStatus();

      final state = container.read(networkStatusProvider);
      expect(state.status, NetworkStatus.serverUnreachable);
      expect(state.isServerUnreachable, isTrue);
    });
  });

  group('NetworkStatusNotifier — reportFailure', () {
    test('reportFailure(Failure.networkError()) เปลี่ยนสถานะเป็น noInternet ทันที', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      notifier.reportFailure(const Failure.networkError());

      final state = container.read(networkStatusProvider);
      expect(state.status, NetworkStatus.noInternet);
    });

    test('reportFailure แจ้งเตือนปิดปรับปรุงเมื่อได้ข้อความ maintenance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      notifier.reportFailure(const Failure.serverError(
        'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง',
      ));

      final state = container.read(networkStatusProvider);
      expect(state.status, NetworkStatus.serverMaintenance);
    });

    test('reportFailure แจ้งเตือน serverUnreachable เมื่อไม่สามารถเชื่อมต่อเซิร์ฟเวอร์', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(networkStatusProvider.notifier);
      notifier.reportFailure(const Failure.serverError(
        'ไม่สามารถเชื่อมต่อกับ Server ได้ กรุณาตรวจสอบว่า Backend กำลังทำงานอยู่',
      ));

      final state = container.read(networkStatusProvider);
      expect(state.status, NetworkStatus.serverUnreachable);
    });
  });
}

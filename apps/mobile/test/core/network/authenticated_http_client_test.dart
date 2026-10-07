import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';

/// เก็บ header ของ request ที่หลุดออกไปจริง เพื่อ assert ว่าแนบ/ไม่แนบถูกต้อง
class _Capture {
  Map<String, String>? headers;
  Uri? url;
  int callCount = 0;
}

MockClient _mockReturning(int statusCode, _Capture capture) {
  return MockClient((request) async {
    capture.headers = Map<String, String>.from(request.headers);
    capture.url = request.url;
    capture.callCount++;
    return http.Response('{}', statusCode);
  });
}

String? _authHeaderOf(_Capture capture) {
  final headers = capture.headers;
  if (headers == null) return null;
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == 'authorization') return entry.value;
  }
  return null;
}

void main() {
  group('การแนบ Bearer token', () {
    test('แนบ token เมื่อมี token และไม่ใช่ public path', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/subscriptions'));

      expect(_authHeaderOf(capture), 'Bearer jwt-abc');
    });

    test('ไม่ส่ง header เลยเมื่อไม่มี token (null)', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => null,
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/subscriptions'));

      expect(_authHeaderOf(capture), isNull);
    });

    test('ไม่ส่ง header เมื่อ token เป็นสตริงว่าง', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => '',
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/users/me'));

      expect(
        _authHeaderOf(capture),
        isNull,
        reason: 'ส่ง "Bearer " เปล่า ๆ จะได้ 401 ที่แยกสาเหตุไม่ออก',
      );
    });

    test('ไม่เขียนทับ Authorization ที่ caller ตั้งมาเอง', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-from-storage',
        inner: _mockReturning(200, capture),
      );

      await client.get(
        Uri.parse('http://localhost:3000/users/me'),
        headers: {'Authorization': 'Bearer caller-supplied'},
      );

      expect(_authHeaderOf(capture), 'Bearer caller-supplied');
    });

    test('อ่าน token ใหม่ทุก request ไม่ cache ค่าเก่า', () async {
      final capture = _Capture();
      var current = 'first';
      final client = AuthenticatedHttpClient(
        readToken: () async => current,
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/users/me'));
      expect(_authHeaderOf(capture), 'Bearer first');

      current = 'second';
      await client.get(Uri.parse('http://localhost:3000/users/me'));
      expect(_authHeaderOf(capture), 'Bearer second');
    });
  });

  group('public path ข้ามการแนบ token', () {
    for (final path in kPublicAuthPaths) {
      test('$path ไม่แนบ token แม้จะมี token ค้างอยู่', () async {
        final capture = _Capture();
        final client = AuthenticatedHttpClient(
          readToken: () async => 'stale-jwt',
          inner: _mockReturning(200, capture),
        );

        await client.post(Uri.parse('http://localhost:3000$path'));

        expect(_authHeaderOf(capture), isNull);
      });
    }

    test('path ที่ไม่ได้อยู่ในรายการ public ยังแนบตามปกติ', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/notifications'));

      expect(_authHeaderOf(capture), 'Bearer jwt-abc');
    });

    test('เทียบ path แบบตรงตัว ไม่ใช่ prefix', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: _mockReturning(200, capture),
      );

      // ไม่ใช่ /auth/login จึงต้องแนบ token
      await client.get(Uri.parse('http://localhost:3000/auth/login/extra'));

      expect(_authHeaderOf(capture), 'Bearer jwt-abc');
    });

    test('inject ชุด publicPaths เองได้', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: _mockReturning(200, capture),
        publicPaths: const {'/packages'},
      );

      await client.get(Uri.parse('http://localhost:3000/packages'));

      expect(_authHeaderOf(capture), isNull);
    });

    test('readToken ไม่ถูกเรียกเลยสำหรับ public path', () async {
      final capture = _Capture();
      var readCount = 0;
      final client = AuthenticatedHttpClient(
        readToken: () async {
          readCount++;
          return 'jwt-abc';
        },
        inner: _mockReturning(200, capture),
      );

      await client.post(Uri.parse('http://localhost:3000/auth/login'));

      expect(readCount, 0);
    });
  });

  group('สัญญาณ 401', () {
    test('ยิงเมื่อได้ 401 จาก path ที่ต้อง auth', () async {
      final capture = _Capture();
      var signals = 0;
      final client = AuthenticatedHttpClient(
        readToken: () async => 'expired-jwt',
        inner: _mockReturning(401, capture),
        onUnauthorized: () => signals++,
      );

      await client.get(Uri.parse('http://localhost:3000/subscriptions'));

      expect(signals, 1);
    });

    test('ไม่ยิงเมื่อ 401 มาจาก /auth/login (รหัสผ่านผิด ไม่ใช่ session หมดอายุ)',
        () async {
      final capture = _Capture();
      var signals = 0;
      final client = AuthenticatedHttpClient(
        readToken: () async => null,
        inner: _mockReturning(401, capture),
        onUnauthorized: () => signals++,
      );

      await client.post(Uri.parse('http://localhost:3000/auth/login'));

      expect(signals, 0);
    });

    // ครอบ public path ให้ครบทั้ง 3 ตัว ไม่ใช่แค่ /auth/login
    //
    // `POST /auth/social` ตอบ 401 ได้จริงเมื่อ Google ID token ไม่ผ่านการตรวจ
    // (`auth.service.ts` โยน UnauthorizedException) ถ้าสัญญาณยิงตรงนั้น XC-3
    // จะแปลว่า "ล็อกอินด้วย Google ไม่สำเร็จ" = "คุณถูกเตะออกจากระบบ"
    for (final path in kPublicAuthPaths) {
      test('401 จาก $path ไม่ยิงสัญญาณ', () async {
        final capture = _Capture();
        var signals = 0;
        final client = AuthenticatedHttpClient(
          readToken: () async => null,
          inner: _mockReturning(401, capture),
          onUnauthorized: () => signals++,
        );

        await client.post(Uri.parse('http://localhost:3000$path'));

        expect(signals, 0);
      });
    }

    // แยกเหตุผลให้ชัด: ที่ไม่ยิงเพราะ "เป็น public path" ไม่ใช่เพราะ "ไม่มี token"
    //
    // เคสจริงที่เกิดได้: ผู้ใช้ยังมี token เก่าค้างอยู่ใน storage แล้วกรอกรหัสผ่าน
    // ผิดตอน login ใหม่ — ต้องไม่ถูกตีความว่า session หมดอายุ
    for (final path in kPublicAuthPaths) {
      test('401 จาก $path ไม่ยิงสัญญาณ แม้จะมี token เก่าค้างอยู่', () async {
        final capture = _Capture();
        var signals = 0;
        final client = AuthenticatedHttpClient(
          readToken: () async => 'stale-jwt-from-previous-session',
          inner: _mockReturning(401, capture),
          onUnauthorized: () => signals++,
        );

        await client.post(Uri.parse('http://localhost:3000$path'));

        expect(
          signals,
          0,
          reason: 'public path ต้องไม่ยิงสัญญาณไม่ว่าจะมี token หรือไม่',
        );
        expect(
          _authHeaderOf(capture),
          isNull,
          reason: 'และต้องไม่แนบ token เก่าไปกับ request ด้วย',
        );
      });
    }

    test('401 จาก path ที่ต้อง auth หลายเส้นทาง ยิงครบทุกเส้น', () async {
      for (final path in ['/users/me', '/subscriptions', '/cards',
        '/notifications', '/savings/optimizer', '/creep-score']) {
        final capture = _Capture();
        var signals = 0;
        final client = AuthenticatedHttpClient(
          readToken: () async => 'expired-jwt',
          inner: _mockReturning(401, capture),
          onUnauthorized: () => signals++,
        );

        await client.get(Uri.parse('http://localhost:3000$path'));

        expect(signals, 1, reason: '401 จาก $path ต้องยิงสัญญาณ');
      }
    });

    test('403 จาก path ที่ต้อง auth ไม่ยิงสัญญาณ (PIN ผิด ไม่ใช่ session หมดอายุ)',
        () async {
      // `POST /savings/batch-cancel` ตอบ 403 เมื่อ PIN ผิด — ไม่ใช่เรื่อง session
      final capture = _Capture();
      var signals = 0;
      final client = AuthenticatedHttpClient(
        readToken: () async => 'valid-jwt',
        inner: _mockReturning(403, capture),
        onUnauthorized: () => signals++,
      );

      await client.post(Uri.parse('http://localhost:3000/savings/batch-cancel'));

      expect(signals, 0);
    });

    test('ไม่ยิงสำหรับสถานะอื่น', () async {
      for (final status in [200, 201, 400, 403, 404, 409, 500]) {
        final capture = _Capture();
        var signals = 0;
        final client = AuthenticatedHttpClient(
          readToken: () async => 'jwt-abc',
          inner: _mockReturning(status, capture),
          onUnauthorized: () => signals++,
        );

        await client.get(Uri.parse('http://localhost:3000/subscriptions'));

        expect(signals, 0, reason: 'HTTP $status ไม่ควรยิงสัญญาณ 401');
      }
    });

    test('ยิงทุกครั้งที่เจอ 401 ไม่ใช่ครั้งเดียว', () async {
      final capture = _Capture();
      var signals = 0;
      final client = AuthenticatedHttpClient(
        readToken: () async => 'expired-jwt',
        inner: _mockReturning(401, capture),
        onUnauthorized: () => signals++,
      );

      await client.get(Uri.parse('http://localhost:3000/subscriptions'));
      await client.get(Uri.parse('http://localhost:3000/notifications'));

      expect(signals, 2);
    });

    test('ไม่ตั้ง onUnauthorized ก็ไม่พัง', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'expired-jwt',
        inner: _mockReturning(401, capture),
      );

      final response =
          await client.get(Uri.parse('http://localhost:3000/subscriptions'));

      expect(response.statusCode, 401);
    });

    for (final path in kUnauthorizedExemptPaths) {
      test('401 จาก $path ไม่ยิงสัญญาณ onUnauthorized (เช่น PIN เดิมผิด)',
          () async {
        final capture = _Capture();
        var signals = 0;
        final client = AuthenticatedHttpClient(
          readToken: () async => 'jwt-valid',
          inner: _mockReturning(401, capture),
          onUnauthorized: () => signals++,
        );

        await client.patch(Uri.parse('http://localhost:3000$path'));

        expect(signals, 0,
            reason: '401 จาก $path ต้องไม่ยิงสัญญาณ session หมดอายุ');
        expect(
          _authHeaderOf(capture),
          'Bearer jwt-valid',
          reason: '$path ยังคงต้องแนบ Bearer token ตามปกติ (ไม่ใช่ public path)',
        );
      });
    }

    test('สามารถ inject unauthorizedExemptPaths เองได้', () async {
      final capture = _Capture();
      var signals = 0;
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-valid',
        inner: _mockReturning(401, capture),
        unauthorizedExemptPaths: const {'/custom/exempt'},
        onUnauthorized: () => signals++,
      );

      await client.post(Uri.parse('http://localhost:3000/custom/exempt'));
      expect(signals, 0);

      await client.post(Uri.parse('http://localhost:3000/users/pin'));
      expect(signals, 1,
          reason:
              'เมื่อ override แล้ว path เดิมที่ไม่ถูกระบุต้องยิงสัญญาณตามปกติ');
    });
  });

  group('ส่งต่อ request ตามเดิม', () {
    test('ไม่เปลี่ยน URL และยิง inner client ครั้งเดียว', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/cards?limit=5'));

      expect(capture.url.toString(), 'http://localhost:3000/cards?limit=5');
      expect(capture.callCount, 1);
    });

    test('ส่ง body และ header อื่นผ่านไปครบ', () async {
      final capture = _Capture();
      String? seenBody;
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: MockClient((request) async {
          capture.headers = Map<String, String>.from(request.headers);
          seenBody = request.body;
          return http.Response('{}', 200);
        }),
      );

      await client.post(
        Uri.parse('http://localhost:3000/subscriptions'),
        headers: {'Content-Type': 'application/json'},
        body: '{"name":"Netflix"}',
      );

      expect(seenBody, '{"name":"Netflix"}');
      expect(_authHeaderOf(capture), 'Bearer jwt-abc');
    });
  });
}

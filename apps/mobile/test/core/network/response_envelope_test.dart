import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/response_envelope.dart';

/// payload ตัวอย่างที่ `parseData` จะได้รับ (เนื้อใน `data` เท่านั้น)
Map<String, dynamic> _identity(Map<String, dynamic> data) => data;

http.Response _json(Object body, int statusCode) => http.Response(
      body is String ? body : jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('unwrapEnvelope — success', () {
    test('คืน data ที่อยู่ใน envelope ไม่ใช่ body ทั้งก้อน', () {
      final response = _json({
        'success': true,
        'statusCode': 200,
        'data': {'token': 'jwt-abc', 'user': {'id': 'u-1'}},
        'timestamp': '2026-10-06T07:00:00.000Z',
      }, 200);

      final result = unwrapEnvelope(response, _identity);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('คาดว่า Right แต่ได้ Left: $failure'),
        (data) {
          expect(data['token'], 'jwt-abc');
          // พิสูจน์ว่าแกะมาชั้นเดียวจริง ไม่ได้คืน body ทั้งก้อน
          expect(data.containsKey('success'), isFalse);
          expect(data.containsKey('timestamp'), isFalse);
        },
      );
    });

    test('201 Created ถือว่าสำเร็จเหมือน 200', () {
      final response = _json({
        'success': true,
        'statusCode': 201,
        'data': {'token': 'jwt-new'},
        'timestamp': '2026-10-06T07:00:00.000Z',
      }, 201);

      expect(unwrapEnvelope(response, _identity).isRight(), isTrue);
    });

    test('parseData ถูกเรียกครั้งเดียวด้วย data ที่แกะแล้ว', () {
      var callCount = 0;
      Map<String, dynamic> spy(Map<String, dynamic> data) {
        callCount++;
        return data;
      }

      final response = _json({
        'success': true,
        'statusCode': 200,
        'data': {'ok': true},
        'timestamp': '2026-10-06T07:00:00.000Z',
      }, 200);

      unwrapEnvelope(response, spy);
      expect(callCount, 1);
    });
  });

  group('unwrapEnvelope — error envelope', () {
    test('message เป็น String → serverError ที่ถือข้อความนั้น', () {
      final response = _json({
        'success': false,
        'statusCode': 409,
        'timestamp': '2026-10-06T07:00:00.000Z',
        'path': '/auth/register',
        'message': 'An account with this email already exists',
        'error': 'Conflict',
      }, 409);

      final result = unwrapEnvelope(response, _identity);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.displayMessage,
          'An account with this email already exists',
        ),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });

    test('message เป็น List (validation หลายข้อ) → join ด้วยขึ้นบรรทัดใหม่', () {
      final response = _json({
        'success': false,
        'statusCode': 400,
        'timestamp': '2026-10-06T07:00:00.000Z',
        'path': '/auth/register',
        'message': [
          'email must be an email',
          'password must be longer than or equal to 6 characters',
        ],
        'error': 'Bad Request',
      }, 400);

      final result = unwrapEnvelope(response, _identity);

      result.fold(
        (failure) => expect(
          failure.displayMessage,
          'email must be an email\n'
          'password must be longer than or equal to 6 characters',
        ),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });

    test('401 → Failure.unauthorized() ไม่ใช่ serverError', () {
      final response = _json({
        'success': false,
        'statusCode': 401,
        'message': 'Invalid email or password',
        'error': 'Unauthorized',
      }, 401);

      final result = unwrapEnvelope(response, _identity);

      result.fold(
        (failure) => expect(failure, const Failure.unauthorized()),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });

    test('404 → Failure.notFound()', () {
      final response = _json({
        'success': false,
        'statusCode': 404,
        'message': 'Subscription with ID x not found',
        'error': 'Not Found',
      }, 404);

      final result = unwrapEnvelope(response, _identity);

      result.fold(
        (failure) => expect(failure, const Failure.notFound()),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });

    test('error body ที่ไม่มี message เลย ยังได้ Failure ไม่ throw', () {
      final response = _json({'success': false, 'statusCode': 500}, 500);

      final result = unwrapEnvelope(response, _identity);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.displayMessage, contains('500')),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });

    test('message เป็น List ว่าง ไม่ทำให้ได้ข้อความว่าง', () {
      final response = _json({
        'success': false,
        'statusCode': 400,
        'message': <String>[],
      }, 400);

      unwrapEnvelope(response, _identity).fold(
        (failure) => expect(failure.displayMessage.trim(), isNotEmpty),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });
  });

  group('unwrapEnvelope — body ที่พัง', () {
    test('ไม่ใช่ JSON เลย → Failure ไม่ throw', () {
      final response = http.Response('<html>502 Bad Gateway</html>', 502);

      final result = unwrapEnvelope(response, _identity);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.displayMessage, contains('502')),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });

    test('body ว่างเปล่า → Failure ไม่ throw', () {
      final result = unwrapEnvelope(http.Response('', 204), _identity);
      expect(result.isLeft(), isTrue);
    });

    test('JSON ที่เป็น array ระดับบนสุด → Failure', () {
      final result = unwrapEnvelope(_json([1, 2, 3], 200), _identity);
      expect(result.isLeft(), isTrue);
    });

    test('success:true แต่ data เป็น string (เช่น GET /) → Failure', () {
      final response = _json({
        'success': true,
        'statusCode': 200,
        'data': 'Hello World!',
        'timestamp': '2026-10-06T07:00:00.000Z',
      }, 200);

      expect(unwrapEnvelope(response, _identity).isLeft(), isTrue);
    });

    test('success:true แต่ data เป็น list → Failure (รอ unwrapEnvelopeList)', () {
      final response = _json({
        'success': true,
        'statusCode': 200,
        'data': [
          {'id': 'sub-1'},
        ],
        'timestamp': '2026-10-06T07:00:00.000Z',
      }, 200);

      expect(unwrapEnvelope(response, _identity).isLeft(), isTrue);
    });
  });

  group('unwrapEnvelope — 2xx ที่ไม่มี envelope (bug เดิม)', () {
    test('shape แบนแบบเก่า {token, user} ต้องถือว่าล้มเหลว', () {
      // นี่คือ shape ที่โค้ดเดิมอ่านได้และสร้าง User ปลอมขึ้นมา
      final response = _json({
        'token': 'jwt-abc',
        'user': {'id': 'u-1', 'email': 'a@b.c'},
      }, 200);

      final result = unwrapEnvelope(response, _identity);

      expect(
        result.isLeft(),
        isTrue,
        reason: '200 ที่ไม่มี success:true ต้องไม่ถูกนับว่าสำเร็จ',
      );
    });

    test('success:false ที่มากับ 200 ก็ต้องล้มเหลว', () {
      final response = _json({
        'success': false,
        'statusCode': 200,
        'message': 'something is off',
      }, 200);

      expect(unwrapEnvelope(response, _identity).isLeft(), isTrue);
    });
  });

  group('statusOverrides', () {
    test('override ชนะ และไม่แตะ body เลย', () {
      const thai = Failure.serverError('อีเมลนี้ถูกลงทะเบียนไว้แล้วในระบบ');
      final response = _json({
        'success': false,
        'statusCode': 409,
        'message': 'An account with this email already exists',
      }, 409);

      final result = unwrapEnvelope(
        response,
        _identity,
        statusOverrides: {409: thai},
      );

      result.fold(
        (failure) => expect(failure, thai),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });

    test('override ทำงานแม้ body จะพังจน parse ไม่ได้', () {
      const thai = Failure.serverError('อีเมลนี้ถูกลงทะเบียนไว้แล้วในระบบ');
      final response = http.Response('not json at all', 409);

      unwrapEnvelope(response, _identity, statusOverrides: {409: thai}).fold(
        (failure) => expect(failure, thai),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });

    test('override ไม่กระทบสถานะอื่น', () {
      const thai = Failure.serverError('อีเมลนี้ถูกลงทะเบียนไว้แล้วในระบบ');
      final response = _json({
        'success': false,
        'statusCode': 401,
        'message': 'Invalid email or password',
      }, 401);

      unwrapEnvelope(response, _identity, statusOverrides: {409: thai}).fold(
        (failure) => expect(failure, const Failure.unauthorized()),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });

    test('503 Service Unavailable (maintenance) ถอดข้อความแจ้งเตือนปิดปรับปรุง', () {
      final response = _json({
        'statusCode': 503,
        'message': 'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง',
        'error': 'Service Unavailable',
      }, 503);

      final result = unwrapEnvelope(response, _identity);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.displayMessage,
          'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง',
        ),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });

    test('503 ที่ตอบกลับแบบ non-json คืนข้อความปิดปรับปรุงมาตรฐาน', () {
      final response = http.Response('Service Unavailable', 503);

      final result = unwrapEnvelope(response, _identity);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.displayMessage,
          'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง',
        ),
        (data) => fail('คาดว่า Left แต่ได้ Right: $data'),
      );
    });
  });
}

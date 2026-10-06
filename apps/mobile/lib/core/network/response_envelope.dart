import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';

/// แกะ response envelope ที่ NestJS ห่อมาให้ทุก endpoint
///
/// ฝั่ง backend ห่อ response ไว้ 2 รูปแบบที่ **ไม่เหมือนกัน**:
///
/// สำเร็จ (`TransformInterceptor`, ผูก global ที่ `app.module.ts`):
/// ```json
/// {"success": true, "statusCode": 200, "data": <payload>, "timestamp": "..."}
/// ```
/// payload ของจริงซ้อนอยู่ใน `data`
///
/// ผิดพลาด (`HttpExceptionFilter`, ผูก global เช่นกัน):
/// ```json
/// {"success": false, "statusCode": 401, "timestamp": "...", "path": "/auth/login",
///  "message": "..." | ["...", "..."], "error": "Unauthorized"}
/// ```
/// **ไม่มี `data`** และ `message` อยู่ระดับบนสุด — นี่คือเหตุผลที่โค้ดเดิมอ่าน error
/// ได้ถูกอยู่แล้วแต่อ่าน success ผิด
///
/// [parseData] จะได้รับ **เนื้อใน `data`** ไม่ใช่ body ทั้งก้อน
///
/// [statusOverrides] ให้ caller กำหนด [Failure] เฉพาะสถานะได้ เช่น 409 ของ
/// `/auth/register` ที่ต้องการข้อความไทยแทนข้อความอังกฤษจาก backend
Either<Failure, T> unwrapEnvelope<T>(
  http.Response response,
  T Function(Map<String, dynamic> data) parseData, {
  Map<int, Failure> statusOverrides = const {},
}) {
  final statusCode = response.statusCode;

  // caller ขอ override สถานะนี้ไว้ ไม่ต้องแตะ body เลย
  final override = statusOverrides[statusCode];
  if (override != null) return left(override);

  final Object? decoded;
  try {
    decoded = jsonDecode(response.body);
  } catch (_) {
    if (statusCode == 503) {
      return left(const Failure.serverError(
        'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง',
      ));
    }
    return left(Failure.serverError(_malformedMessage(statusCode)));
  }

  if (decoded is! Map<String, dynamic>) {
    return left(Failure.serverError(_malformedMessage(statusCode)));
  }

  final isSuccessEnvelope = decoded['success'] == true;
  final isSuccessStatus = statusCode >= 200 && statusCode < 300;

  if (isSuccessStatus && isSuccessEnvelope) {
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      // endpoint ที่คืน list หรือ primitive (เช่น `GET /` คืน string) ยังไม่รองรับ
      // ที่นี่ — รอ unwrapEnvelopeList ตอน wiring subscriptions
      return left(Failure.serverError(_malformedMessage(statusCode)));
    }
    return right(parseData(data));
  }

  if (isSuccessStatus && !isSuccessEnvelope) {
    // 2xx แต่ไม่มี envelope: เป็น response ที่ไม่ได้ผ่าน TransformInterceptor
    // (ของปลอม, proxy แทรก, หรือ API คนละตัว) ห้ามถือว่าสำเร็จเด็ดขาด —
    // เคสนี้คือ bug เดิมที่ทำให้ได้ User ปลอมโดยไม่มี token
    return left(Failure.serverError(_malformedMessage(statusCode)));
  }

  return left(failureFromErrorBody(decoded, statusCode));
}

/// แปลง error envelope เป็น [Failure] โดยใช้ union เดิมใน `core/errors/failures.dart`
/// ไม่สร้างชนิด error ตัวที่สอง
Failure failureFromErrorBody(Map<String, dynamic> body, int statusCode) {
  // TODO(XC-3/XC-8): confirmed not shown in the XC-3 restore flow; still wrong if login-wrong-password UX changes later.
  // `Failure.unauthorized()` มีข้อความตายตัวว่า "อีเมลหรือรหัสผ่านไม่ถูกต้อง"
  // ใน XC-3 เส้นทาง session restore เมื่อเจอ 401 จะ transition ไป data(null) โดยตรง
  // ไม่เคยนำ displayMessage ไปแสดง แต่หากในอนาคต UX ฝั่ง login เปลี่ยน หรือทำ XC-8
  // ต้องเพิ่มพารามิเตอร์ข้อความให้ variant นี้ (ต้อง regenerate failures.freezed.dart)
  if (statusCode == 401) return const Failure.unauthorized();
  if (statusCode == 404) return const Failure.notFound();
  if (statusCode == 503) {
    final message = extractErrorMessage(body);
    return Failure.serverError(
      message ?? 'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง',
    );
  }

  final message = extractErrorMessage(body);
  if (message != null) return Failure.serverError(message);

  return Failure.serverError(_malformedMessage(statusCode));
}

/// ดึงข้อความ error จาก body — รองรับทั้ง `String` และ `List`
///
/// `class-validator` ฝั่ง backend คืน `message` เป็น array เมื่อ validate ไม่ผ่าน
/// หลายข้อพร้อมกัน เช่น
/// `["email must be an email", "password must be longer than or equal to 6 characters"]`
String? extractErrorMessage(Map<String, dynamic> body) {
  final message = body['message'];

  if (message is String && message.isNotEmpty) return message;

  if (message is List && message.isNotEmpty) {
    // คั่นด้วยขึ้นบรรทัดใหม่ ไม่ใช่ ", " แบบโค้ดเดิม: validation error หลายข้อ
    // ต่อกันด้วย comma อ่านแทบไม่ออกใน SnackBar บรรทัดเดียว
    return message.map((item) => item.toString()).join('\n');
  }

  return null;
}

String _malformedMessage(int statusCode) =>
    'เซิร์ฟเวอร์ตอบกลับในรูปแบบที่ไม่รู้จัก (HTTP $statusCode)';

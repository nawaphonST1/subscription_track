import 'package:http/http.dart' as http;

/// Path ที่ backend ติด `@Public()` ไว้ จึงไม่ต้องใช้ Bearer token
///
/// ตรงกับ `apps/server/src/auth/auth.controller.ts` ที่ `@Public()` อยู่บน
/// `register` / `login` / `social` เท่านั้น ส่วน `GET /` กับ `GET /health` ก็
/// public เหมือนกันแต่แอปไม่ได้เรียก จึงไม่ใส่ไว้
///
/// ถ้าฝั่ง backend เพิ่ม `@Public()` route ใหม่ ต้องมาเพิ่มที่นี่ด้วย
const Set<String> kPublicAuthPaths = {
  '/auth/register',
  '/auth/login',
  '/auth/social',
};

/// Path ที่ตอบ 401 เมื่อข้อมูลทางธุรกิจไม่ถูกต้อง (เช่น PIN เดิมผิด)
/// ไม่ใช่ session หมดอายุ จึงไม่ควรยิงสัญญาณ [onUnauthorized]
const Set<String> kUnauthorizedExemptPaths = {
  '/users/pin',
};

/// http.Client ที่แนบ `Authorization: Bearer <token>` ให้ request ขาออกอัตโนมัติ
///
/// ก่อนหน้านี้ไม่มีที่ไหนในแอปแนบ header นี้เลย ทำให้ 39 จาก 44 routes ของ
/// backend เรียกไม่ได้แม้จะเขียนโค้ดเรียกไว้แล้ว
///
/// [readToken] ถูก inject เข้ามาแทนที่จะเรียก `SharedPreferences` ตรง ๆ เพื่อให้
/// ทดสอบได้โดยไม่ต้องมี plugin binding และเพื่อให้เปลี่ยนไปใช้ secure storage
/// ภายหลังได้โดยไม่ต้องแก้คลาสนี้
class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient({
    required this.readToken,
    http.Client? inner,
    this.publicPaths = kPublicAuthPaths,
    this.unauthorizedExemptPaths = kUnauthorizedExemptPaths,
    this.onUnauthorized,
  }) : _inner = inner ?? http.Client();

  /// อ่าน token ปัจจุบัน ถูกเรียกใหม่ทุก request จึงไม่ค้างค่าเก่าหลัง login/logout
  final Future<String?> Function() readToken;

  /// Path ที่ไม่ต้องแนบ token
  final Set<String> publicPaths;

  /// Path ที่ยกเว้นการยิงสัญญาณ 401
  final Set<String> unauthorizedExemptPaths;

  /// ยิงเมื่อ request ที่ต้อง auth ได้ 401 กลับมา
  ///
  /// ตั้งใจให้เป็นแค่ "สัญญาณ" งานนี้ยังไม่ต่อเข้า app shell — การ logout และพา
  /// ผู้ใช้กลับหน้า login ขึ้นกับ session restore (XC-3) ที่ยังไม่ได้ทำ
  final void Function()? onUnauthorized;

  final http.Client _inner;

  static const String authorizationHeader = 'authorization';

  bool isPublicPath(String path) => publicPaths.contains(path);

  bool isUnauthorizedExemptPath(String path) =>
      unauthorizedExemptPaths.contains(path);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isPublic = isPublicPath(request.url.path);
    final isExempt = isUnauthorizedExemptPath(request.url.path);

    // ไม่เขียนทับถ้า caller ตั้ง Authorization มาเองแล้ว
    final alreadySet = request.headers.keys
        .any((key) => key.toLowerCase() == authorizationHeader);

    if (!isPublic && !alreadySet) {
      final token = await readToken();
      // token ว่าง = ไม่ส่ง header เลย ดีกว่าส่ง "Bearer " เปล่า ๆ ซึ่ง backend
      // จะตอบ 401 แบบที่แยกไม่ออกว่าเพราะยังไม่ login หรือ token หมดอายุ
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await _inner.send(request);

    // 401 จาก public path คือ "รหัสผ่านผิด" ไม่ใช่ "session หมดอายุ" จึงไม่ยิงสัญญาณ
    // 401 จาก exempt path (เช่น /users/pin) คือ "PIN ไม่ถูกต้อง" จึงไม่ยิงสัญญาณเช่นกัน
    if (response.statusCode == 401 && !isPublic && !isExempt) {
      onUnauthorized?.call();
    }

    return response;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

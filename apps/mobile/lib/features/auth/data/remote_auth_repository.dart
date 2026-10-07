import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/core/network/response_envelope.dart';
import 'package:subscription_track/core/utils/logger.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

/// payload ที่ 3 endpoint ของ auth คืนมาใน `data` ของ envelope
typedef _AuthPayload = ({String? token, User user});

class RemoteAuthRepository implements AuthRepository {
  final http.Client _client;
  final String _baseUrl;
  final GoogleSignIn? _googleSignIn;

  /// [client] ที่ส่งเข้ามาจะถูกห่อด้วย [AuthenticatedHttpClient] เสมอ เพื่อให้
  /// request ที่ไม่ใช่ public path ได้ Bearer token ติดไปด้วยอัตโนมัติ
  /// (3 endpoint ของ auth เองเป็น public จึงไม่ได้รับผลตรงนี้ แต่การห่อไว้ทำให้
  /// repository ตัวอื่นที่จะมาทีหลังใช้ pattern เดียวกันได้)
  RemoteAuthRepository({
    http.Client? client,
    String? baseUrl,
    GoogleSignIn? googleSignIn,
    void Function()? onUnauthorized,
  })  : _client = AuthenticatedHttpClient(
          readToken: readStoredAuthToken,
          inner: client,
          onUnauthorized: onUnauthorized,
        ),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        // ignore: prefer_initializing_formals
        _googleSignIn = googleSignIn;

  static const String _tokenKey = 'auth_token';

  /// อ่าน token ที่เก็บไว้ ใช้เป็น [AuthenticatedHttpClient.readToken]
  ///
  /// ยังเก็บใน SharedPreferences ตามเดิม — การย้ายไป secure storage อยู่นอก
  /// ขอบเขตงานนี้
  static Future<String?> readStoredAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    String? name,
    String? securityPin,
  }) async {
    final http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/auth/register');
      logger.i('Calling API: POST $uri');
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (name != null && name.isNotEmpty) 'name': name,
          if (securityPin != null && securityPin.isNotEmpty)
            'security_pin': securityPin,
        }),
      );
    } catch (e, stack) {
      logger.e('Error connecting to register API',
          error: e, stackTrace: stack);
      return left(Failure.serverError(
          'ไม่สามารถเชื่อมต่อกับ Server ได้ ($_baseUrl) กรุณาตรวจสอบว่า Backend API กำลังทำงานอยู่'));
    }

    try {
      return await _resolveAuthResponse(
        response,
        fallbackEmail: email,
        fallbackName: name,
        statusOverrides: const {
          409: Failure.serverError('อีเมลนี้ถูกลงทะเบียนไว้แล้วในระบบ'),
        },
      );
    } catch (e, stack) {
      logger.e('Error parsing register response', error: e, stackTrace: stack);
      return left(
          const Failure.serverError('รูปแบบข้อมูลตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง'));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/auth/login');
      logger.i('Calling API: POST $uri');
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
    } catch (e, stack) {
      logger.e('Error connecting to login API', error: e, stackTrace: stack);
      return left(Failure.serverError(
          'ไม่สามารถเชื่อมต่อกับ Server ได้ ($_baseUrl) กรุณาตรวจสอบว่า Backend API กำลังทำงานอยู่'));
    }

    try {
      // 401 ถูก map เป็น Failure.unauthorized() อยู่แล้วใน unwrapEnvelope
      return await _resolveAuthResponse(response, fallbackEmail: email);
    } catch (e, stack) {
      logger.e('Error parsing login response', error: e, stackTrace: stack);
      return left(
          const Failure.serverError('รูปแบบข้อมูลตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง'));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithGoogle() async {
    try {
      final googleSignIn = _googleSignIn ??
          GoogleSignIn(
            clientId: kIsWeb && ApiConfig.googleClientId.isNotEmpty
                ? ApiConfig.googleClientId
                : null,
            serverClientId: (!kIsWeb && ApiConfig.googleClientId.isNotEmpty)
                ? ApiConfig.googleClientId
                : null,
            scopes: ['email', 'profile'],
          );

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        return left(
            const Failure.serverError('การเข้าสู่ระบบด้วย Google ถูกยกเลิก'));
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String tokenToSend =
          auth.idToken ?? auth.accessToken ?? 'mock-google-token';

      return await _socialLogin(
        provider: 'google',
        email: account.email,
        token: tokenToSend,
        name: account.displayName ?? 'Google User',
      );
    } catch (e, stack) {
      logger.e('Google Sign-In failed', error: e, stackTrace: stack);
      final errorStr = e.toString();
      if (errorStr.contains('popup_closed') || errorStr.contains('cancelled')) {
        return left(
            const Failure.serverError('การเข้าสู่ระบบด้วย Google ถูกยกเลิก'));
      }
      return left(Failure.serverError(
          'การเชื่อมต่อ Google ไม่สำเร็จ ($e) กรุณาตรวจสอบการตั้งค่า Google Client ID'));
    }
  }

  @visibleForTesting
  Future<Either<Failure, User>> executeSocialLogin({
    required String provider,
    required String email,
    required String token,
    required String name,
  }) =>
      _socialLogin(
        provider: provider,
        email: email,
        token: token,
        name: name,
      );

  Future<Either<Failure, User>> _socialLogin({
    required String provider,
    required String email,
    required String token,
    required String name,
  }) async {
    final http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/auth/social');
      logger.i('Calling API: POST $uri ($provider)');
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'email': email,
          'token': token,
          'name': name,
        }),
      );
    } catch (e, stack) {
      logger.e('Error connecting to social login API',
          error: e, stackTrace: stack);
      return left(Failure.serverError(
          'ไม่สามารถเชื่อมต่อกับ Server ได้ ($_baseUrl) กรุณาตรวจสอบว่า Backend API กำลังทำงานอยู่'));
    }

    try {
      return await _resolveAuthResponse(
        response,
        fallbackEmail: email,
        fallbackName: name,
        provider: provider,
      );
    } catch (e, stack) {
      logger.e('Error parsing social login response',
          error: e, stackTrace: stack);
      return left(
          const Failure.serverError('รูปแบบข้อมูลตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    // ไม่มี token = ไม่เคย login (หรือ logout ไปแล้ว) ⇒ ตอบทันทีโดยไม่ยิง network
    // ถ้าปล่อยให้ยิงไป backend จะตอบ 401 อยู่ดี แต่เสียเวลารอเน็ตตอนเปิดแอป
    final token = await readStoredAuthToken();
    if (token == null || token.isEmpty) {
      return left(const Failure.unauthorized());
    }

    final http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/users/me');
      logger.i('Calling API: GET $uri');
      // `/users/me` ไม่อยู่ใน kPublicAuthPaths ⇒ _client แนบ Bearer ให้เอง
      response = await _client.get(uri);
    } catch (e, stack) {
      logger.e('Error connecting to current-user API',
          error: e, stackTrace: stack);
      // แยกจาก serverError โดยตั้งใจ: ผู้เรียกใช้สัญญาใน AuthRepository เพื่อ
      // ตัดสินว่าจะล้าง token หรือไม่ — เคสนี้ต้องไม่ล้าง
      return left(const Failure.networkError());
    }

    try {
      // ต่างจาก 3 endpoint ของ auth: `/users/me` คืน user object ไว้ที่ `data`
      // ตรง ๆ ไม่ได้ซ้อนใต้คีย์ `user` อีกชั้น ⇒ ส่ง _mapJsonToUser เป็น
      // parseData ได้เลย
      return unwrapEnvelope<User>(response, (data) => _mapJsonToUser(data));
    } catch (e, stack) {
      logger.e('Error parsing current-user response',
          error: e, stackTrace: stack);
      return left(
          const Failure.serverError('รูปแบบข้อมูลตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      return right(unit);
    } catch (e) {
      return right(unit);
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}
  }

  static bool _parsePinConfigured(Object? raw) {
    if (raw is bool) return raw;
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    if (raw is num) return raw != 0;
    return false; // fail-closed default
  }

  User _mapJsonToUser(
    Map<String, dynamic> json, {
    String? fallbackEmail,
    String? fallbackName,
    String provider = 'email',
  }) {
    final pinConfigured = _parsePinConfigured(json['pin_configured']);

    return User(
      id: json['id'] as String? ??
          'user-${DateTime.now().millisecondsSinceEpoch}',
      email: json['email'] as String? ?? fallbackEmail ?? '',
      name: json['name'] as String? ?? fallbackName ?? '',
      income: (json['monthly_income'] as num?)?.toDouble() ?? 0.0,
      authProvider: provider,
      currency: 'THB',
      creditCards: const [],
      pinConfigured: pinConfigured,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// แกะ envelope ของ response จาก 3 endpoint auth แล้วเซฟ token
  ///
  /// payload ของจริงอยู่ที่ `body['data']` ซึ่งมีรูป `{token, user}` ส่วน
  /// [_mapJsonToUser] รับ `body['data']['user']` (ลึกไปอีกชั้น) จึงต้องแกะสองชั้น
  /// ใน closure นี้ ไม่ใช่ส่ง [_mapJsonToUser] เป็น parseData ตรง ๆ
  Future<Either<Failure, User>> _resolveAuthResponse(
    http.Response response, {
    required String fallbackEmail,
    String? fallbackName,
    String provider = 'email',
    Map<int, Failure> statusOverrides = const {},
  }) {
    final parsed = unwrapEnvelope<_AuthPayload>(
      response,
      (data) => (
        token: data['token'] as String?,
        user: _mapJsonToUser(
          data['user'] as Map<String, dynamic>? ?? const {},
          fallbackEmail: fallbackEmail,
          fallbackName: fallbackName,
          provider: provider,
        ),
      ),
      statusOverrides: statusOverrides,
    );

    return parsed.fold<Future<Either<Failure, User>>>(
      (failure) async => left(failure),
      (payload) async {
        final token = payload.token;
        if (token == null || token.isEmpty) {
          // envelope ถูกต้องแต่ไม่มี token = contract ฝั่ง backend เพี้ยน
          // ห้ามคืน User สำเร็จ ไม่งั้นจะได้ "login สำเร็จแต่ไม่มี token" แบบ bug เดิม
          return left(const Failure.serverError(
              'เซิร์ฟเวอร์ไม่ได้ส่ง token กลับมา ไม่สามารถเข้าสู่ระบบได้'));
        }
        await _saveToken(token);
        return right(payload.user);
      },
    );
  }
}

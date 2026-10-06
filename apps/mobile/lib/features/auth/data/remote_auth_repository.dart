import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/utils/logger.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

class RemoteAuthRepository implements AuthRepository {
  final http.Client _client;
  final String _baseUrl;
  final GoogleSignIn? _googleSignIn;

  RemoteAuthRepository({
    http.Client? client,
    String? baseUrl,
    GoogleSignIn? googleSignIn,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        // ignore: prefer_initializing_formals
        _googleSignIn = googleSignIn;

  static const String _tokenKey = 'auth_token';

  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/register');
      logger.i('Calling API: POST $uri');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (name != null && name.isNotEmpty) 'name': name,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null) {
          await _saveToken(token);
        }
        final userJson = data['user'] as Map<String, dynamic>? ?? {};
        return right(_mapJsonToUser(userJson,
            fallbackEmail: email, fallbackName: name));
      } else if (response.statusCode == 409) {
        return left(
            const Failure.serverError('อีเมลนี้ถูกลงทะเบียนไว้แล้วในระบบ'));
      } else {
        final errorMsg = _extractErrorMessage(response.body) ??
            'การสมัครสมาชิกล้มเหลว (Status: ${response.statusCode})';
        return left(Failure.serverError(errorMsg));
      }
    } catch (e, stack) {
      logger.e('Error connecting to register API',
          error: e, stackTrace: stack);
      return left(Failure.serverError(
          'ไม่สามารถเชื่อมต่อกับ Server ได้ ($_baseUrl) กรุณาตรวจสอบว่า Backend API กำลังทำงานอยู่'));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/login');
      logger.i('Calling API: POST $uri');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null) {
          await _saveToken(token);
        }
        final userJson = data['user'] as Map<String, dynamic>? ?? {};
        return right(_mapJsonToUser(userJson, fallbackEmail: email));
      } else if (response.statusCode == 401) {
        return left(const Failure.unauthorized());
      } else {
        final errorMsg = _extractErrorMessage(response.body) ??
            'การเข้าสู่ระบบล้มเหลว (Status: ${response.statusCode})';
        return left(Failure.serverError(errorMsg));
      }
    } catch (e, stack) {
      logger.e('Error connecting to login API', error: e, stackTrace: stack);
      return left(Failure.serverError(
          'ไม่สามารถเชื่อมต่อกับ Server ได้ ($_baseUrl) กรุณาตรวจสอบว่า Backend API กำลังทำงานอยู่'));
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

      return _socialLogin(
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

  @override
  Future<Either<Failure, User>> loginWithApple() async {
    // Mock Apple Sign-In (ตามที่ระบุ: apple ใช้ mock เหมือนเดิม)
    return _socialLogin(
      provider: 'apple',
      email: 'user@icloud.com',
      token: 'mock-apple-token',
      name: 'Jane Doe (Apple User)',
    );
  }

  Future<Either<Failure, User>> _socialLogin({
    required String provider,
    required String email,
    required String token,
    required String name,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/social');
      logger.i('Calling API: POST $uri ($provider)');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'email': email,
          'token': token,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final jwtToken = data['token'] as String?;
        if (jwtToken != null) {
          await _saveToken(jwtToken);
        }
        final userJson = data['user'] as Map<String, dynamic>? ?? {};
        return right(_mapJsonToUser(userJson,
            fallbackEmail: email, fallbackName: name, provider: provider));
      } else {
        final errorMsg = _extractErrorMessage(response.body) ??
            'การเข้าสู่ระบบด้วย $provider ล้มเหลว';
        return left(Failure.serverError(errorMsg));
      }
    } catch (e, stack) {
      logger.e('Error connecting to social login API',
          error: e, stackTrace: stack);
      return left(Failure.serverError(
          'ไม่สามารถเชื่อมต่อกับ Server ได้ ($_baseUrl) กรุณาตรวจสอบว่า Backend API กำลังทำงานอยู่'));
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

  User _mapJsonToUser(
    Map<String, dynamic> json, {
    String? fallbackEmail,
    String? fallbackName,
    String provider = 'email',
  }) {
    return User(
      id: json['id'] as String? ??
          'user-${DateTime.now().millisecondsSinceEpoch}',
      email: json['email'] as String? ?? fallbackEmail ?? '',
      name: json['name'] as String? ?? fallbackName ?? '',
      income: (json['monthly_income'] as num?)?.toDouble() ?? 0.0,
      authProvider: provider,
      currency: 'THB',
      creditCards: const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  String? _extractErrorMessage(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        if (parsed['message'] is String) return parsed['message'] as String;
        if (parsed['message'] is List &&
            (parsed['message'] as List).isNotEmpty) {
          return (parsed['message'] as List).join(', ');
        }
      }
    } catch (_) {}
    return null;
  }
}

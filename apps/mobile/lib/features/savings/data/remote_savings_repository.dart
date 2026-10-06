import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/core/network/response_envelope.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/savings/domain/savings_optimizer_report.dart';
import 'package:subscription_track/features/savings/domain/savings_repository.dart';

class InvalidPinException implements Exception {
  const InvalidPinException([this.message = 'รหัส PIN ไม่ถูกต้อง']);
  final String message;

  @override
  String toString() => message;
}

class PinLockoutException implements Exception {
  const PinLockoutException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SavingsException implements Exception {
  const SavingsException(this.message);
  final String message;

  @override
  String toString() => message;
}

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return RemoteSavingsRepository();
});

class RemoteSavingsRepository implements SavingsRepository {
  RemoteSavingsRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client is AuthenticatedHttpClient
            ? client
            : AuthenticatedHttpClient(
                readToken: RemoteAuthRepository.readStoredAuthToken,
                inner: client,
              ),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<SavingsOptimizerReport> getOptimizerReport() async {
    final uri = Uri.parse('$_baseUrl/savings/optimizer');
    final response = await _client.get(uri);

    final result = unwrapEnvelope<SavingsOptimizerReport>(
      response,
      SavingsOptimizerReport.fromJson,
    );

    return result.fold(
      (failure) => throw SavingsException(
        'Failed to load savings optimizer report (HTTP ${response.statusCode}): ${failure.displayMessage}',
      ),
      (report) => report,
    );
  }

  @override
  Future<BatchCancelResult> batchCancel({
    required List<String> subscriptionIds,
    required String pin,
  }) async {
    final uri = Uri.parse('$_baseUrl/savings/batch-cancel');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'subscription_ids': subscriptionIds,
        'security_pin': pin,
      }),
    );

    // Rate-limiting Lockout (429)
    if (response.statusCode == 429) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = body['message'] as String? ??
            'กรอกรหัส PIN ผิดเกินจำนวนครั้งที่กำหนด กรุณารอสักครู่แล้วลองใหม่';
        throw PinLockoutException(msg);
      } catch (e) {
        if (e is PinLockoutException) rethrow;
        throw const PinLockoutException(
          'กรอกรหัส PIN ผิดเกินจำนวนครั้งที่กำหนด กรุณารอสักครู่แล้วลองใหม่',
        );
      }
    }

    // Invalid PIN (403)
    if (response.statusCode == 403) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = body['message'] as String? ?? 'รหัส PIN ไม่ถูกต้อง';
        throw InvalidPinException(msg);
      } catch (e) {
        if (e is InvalidPinException) rethrow;
        throw const InvalidPinException();
      }
    }

    final result = unwrapEnvelope<BatchCancelResult>(
      response,
      BatchCancelResult.fromJson,
    );

    return result.fold(
      (failure) => throw SavingsException(failure.displayMessage),
      (report) => report,
    );
  }
}

import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/core/network/response_envelope.dart';
import 'package:subscription_track/core/security/pin_repository.dart';
import 'package:subscription_track/core/utils/logger.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';

class RemotePinRepository implements PinRepository {
  RemotePinRepository({
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
  Future<Either<Failure, bool>> verifyPin(String pin) async {
    try {
      final uri = Uri.parse('$_baseUrl/users/verify-pin');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      );

      return unwrapEnvelope<bool>(
        response,
        (data) => data['valid'] as bool? ?? false,
      );
    } catch (e, stack) {
      logger.e('Error connecting to verify-pin API', error: e, stackTrace: stack);
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, Unit>> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/users/pin');
      final response = await _client.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_pin': currentPin,
          'new_pin': newPin,
        }),
      );

      return unwrapEnvelope<Unit>(
        response,
        (_) => unit,
      );
    } catch (e, stack) {
      logger.e('Error connecting to change-pin API', error: e, stackTrace: stack);
      return left(const Failure.networkError());
    }
  }
}

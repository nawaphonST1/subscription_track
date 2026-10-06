import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/core/network/response_envelope.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/dashboard/domain/creep_score_report.dart';
import 'package:subscription_track/features/dashboard/domain/creep_score_repository.dart';

final creepScoreRepositoryProvider = Provider<CreepScoreRepository>((ref) {
  return RemoteCreepScoreRepository();
});

class RemoteCreepScoreRepository implements CreepScoreRepository {
  RemoteCreepScoreRepository({
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
  Future<CreepScoreReport> getCreepScore() async {
    final uri = Uri.parse('$_baseUrl/creep-score');
    final response = await _client.get(uri);
    final result = unwrapEnvelope<CreepScoreReport>(
      response,
      CreepScoreReport.fromJson,
    );

    return result.fold(
      (failure) => throw Exception(
        'Failed to load creep score (HTTP ${response.statusCode}): ${failure.displayMessage}',
      ),
      (report) => report,
    );
  }
}

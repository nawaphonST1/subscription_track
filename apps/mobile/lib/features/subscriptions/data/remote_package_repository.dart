import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/core/network/response_envelope.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/subscriptions/domain/package_repository.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_package.dart';

final packageRepositoryProvider = Provider<PackageRepository>((ref) {
  return RemotePackageRepository();
});

final packagesProvider = FutureProvider.autoDispose<List<PresetPackage>>((ref) {
  final repo = ref.watch(packageRepositoryProvider);
  return repo.getPackages();
});

class RemotePackageRepository implements PackageRepository {
  RemotePackageRepository({
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
  Future<List<PresetPackage>> getPackages({
    String? category,
    String? search,
  }) async {
    final queryParams = <String, String>{
      if (category != null && category.isNotEmpty) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final baseUri = Uri.parse('$_baseUrl/packages');
    final uri = queryParams.isNotEmpty
        ? baseUri.replace(queryParameters: queryParams)
        : baseUri;

    final response = await _client.get(uri);
    final result = unwrapEnvelopeList<PresetPackage>(
      response,
      PresetPackage.fromJson,
    );

    return result.fold(
      (failure) => throw Exception(
        'Failed to load packages (HTTP ${response.statusCode}): ${failure.displayMessage}',
      ),
      (packages) => packages,
    );
  }
}

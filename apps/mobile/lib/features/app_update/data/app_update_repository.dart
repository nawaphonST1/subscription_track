import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/app_update/domain/app_update_info.dart';

abstract class AppUpdateRepository {
  Future<AppUpdateInfo?> fetchLatestVersionInfo({String? customManifestUrl});
}

class RemoteAppUpdateRepository implements AppUpdateRepository {
  RemoteAppUpdateRepository({HttpClient? client})
      : _client = client ?? HttpClient();

  final HttpClient _client;

  // Default Azure Blob Storage URL endpoint for subscription_track APK releases
  static const String defaultReleaseManifestUrl =
      'https://subtrackerreleases.blob.core.windows.net/releases/version.json';

  @override
  Future<AppUpdateInfo?> fetchLatestVersionInfo({String? customManifestUrl}) async {
    try {
      final url = Uri.parse(customManifestUrl ?? defaultReleaseManifestUrl);
      final request = await _client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final rawBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> jsonMap =
            jsonDecode(rawBody) as Map<String, dynamic>;
        return AppUpdateInfo.fromJson(jsonMap);
      }
      return null;
    } catch (_) {
      // In case of network errors or offline mode, return null gracefully
      return null;
    }
  }
}

class MockAppUpdateRepository implements AppUpdateRepository {
  MockAppUpdateRepository({this.mockUpdateInfo});

  AppUpdateInfo? mockUpdateInfo;

  @override
  Future<AppUpdateInfo?> fetchLatestVersionInfo({String? customManifestUrl}) async {
    return mockUpdateInfo;
  }
}

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  return RemoteAppUpdateRepository();
});

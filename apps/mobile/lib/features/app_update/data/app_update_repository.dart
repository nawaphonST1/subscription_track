import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/app_update/domain/app_update_info.dart';

abstract class AppUpdateRepository {
  Future<AppUpdateInfo?> fetchLatestVersionInfo({String? customManifestUrl});
  Future<File?> downloadApk({
    required String downloadUrl,
    void Function(int receivedBytes, int totalBytes)? onProgress,
  });
  Future<bool> installApk(String filePath);
  Future<bool> openDownloadUrl(String url);
}

class RemoteAppUpdateRepository implements AppUpdateRepository {
  RemoteAppUpdateRepository({HttpClient? client})
      : _client = client ?? HttpClient();

  final HttpClient _client;

  static const MethodChannel _channel =
      MethodChannel('com.example.subscription_track/app_update');

  // Default Azure Blob Storage URL endpoint for subscription_track APK releases
  static const String defaultReleaseManifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
    defaultValue:
        'https://subtrackerreleases.blob.core.windows.net/releases/version.json',
  );

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

  @override
  Future<File?> downloadApk({
    required String downloadUrl,
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    try {
      final uri = Uri.parse(downloadUrl);
      final request = await _client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        return null;
      }

      final contentLength = response.contentLength;
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/subscription_track_update.apk');
      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (onProgress != null && contentLength > 0) {
          onProgress(receivedBytes, contentLength);
        }
      }

      await sink.flush();
      await sink.close();
      return file;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> installApk(String filePath) async {
    try {
      final res =
          await _channel.invokeMethod<bool>('installApk', {'filePath': filePath});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openDownloadUrl(String url) async {
    try {
      final res =
          await _channel.invokeMethod<bool>('openUrl', {'url': url});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}

class MockAppUpdateRepository implements AppUpdateRepository {
  MockAppUpdateRepository({
    this.mockUpdateInfo,
    this.mockDownloadedFile,
    this.mockInstallSuccess = true,
  });

  AppUpdateInfo? mockUpdateInfo;
  File? mockDownloadedFile;
  bool mockInstallSuccess;
  bool downloadApkCalled = false;
  bool installApkCalled = false;
  bool openDownloadUrlCalled = false;

  @override
  Future<AppUpdateInfo?> fetchLatestVersionInfo({String? customManifestUrl}) async {
    return mockUpdateInfo;
  }

  @override
  Future<File?> downloadApk({
    required String downloadUrl,
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    downloadApkCalled = true;
    onProgress?.call(100, 100);
    return mockDownloadedFile;
  }

  @override
  Future<bool> installApk(String filePath) async {
    installApkCalled = true;
    return mockInstallSuccess;
  }

  @override
  Future<bool> openDownloadUrl(String url) async {
    openDownloadUrlCalled = true;
    return true;
  }
}

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  return RemoteAppUpdateRepository();
});

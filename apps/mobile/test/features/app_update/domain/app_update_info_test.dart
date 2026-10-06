import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/app_update/domain/app_update_info.dart';

void main() {
  group('AppUpdateInfo Domain Tests', () {
    test('correctly identifies when update is available by build number', () {
      const updateInfo = AppUpdateInfo(
        latestVersion: '1.1.0',
        latestBuildNumber: 2,
        minRequiredVersion: '1.0.0',
        minRequiredBuildNumber: 1,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Bug fixes',
      );

      // Current build 1 vs latest 2
      expect(updateInfo.isUpdateAvailable(1, '1.0.0'), isTrue);
      // Current build 2 vs latest 2
      expect(updateInfo.isUpdateAvailable(2, '1.1.0'), isFalse);
      // Current build 3 vs latest 2
      expect(updateInfo.isUpdateAvailable(3, '1.2.0'), isFalse);
    });

    test('correctly identifies when update is available by semver', () {
      const updateInfo = AppUpdateInfo(
        latestVersion: '1.2.0',
        latestBuildNumber: 1,
        minRequiredVersion: '1.0.0',
        minRequiredBuildNumber: 1,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Features',
      );

      expect(updateInfo.isUpdateAvailable(1, '1.1.0'), isTrue);
      expect(updateInfo.isUpdateAvailable(1, '1.2.0'), isFalse);
    });

    test('correctly detects force update condition', () {
      // 1. Explicit forceUpdate flag
      const explicitForced = AppUpdateInfo(
        latestVersion: '1.1.0',
        latestBuildNumber: 2,
        minRequiredVersion: '1.0.0',
        minRequiredBuildNumber: 1,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Critical security fix',
        forceUpdate: true,
      );
      expect(explicitForced.isForceUpdateRequired(1, '1.0.0'), isTrue);

      // 2. Minimum build number required is higher than current
      const buildRequired = AppUpdateInfo(
        latestVersion: '2.0.0',
        latestBuildNumber: 5,
        minRequiredVersion: '1.5.0',
        minRequiredBuildNumber: 3,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Major redesign',
        forceUpdate: false,
      );
      // Below minRequiredBuildNumber (current=2, min=3)
      expect(buildRequired.isForceUpdateRequired(2, '1.4.0'), isTrue);
      // Meets minRequiredBuildNumber (current=3, min=3)
      expect(buildRequired.isForceUpdateRequired(3, '1.5.0'), isFalse);
    });

    test('parses JSON correctly and serializes to JSON', () {
      final json = {
        'latest_version': '1.0.5',
        'latest_build_number': 6,
        'min_required_version': '1.0.2',
        'min_required_build_number': 3,
        'download_url': 'https://azure.blob/app.apk',
        'release_notes': 'Hotfix for payment cards',
        'force_update': true,
      };

      final info = AppUpdateInfo.fromJson(json);
      expect(info.latestVersion, '1.0.5');
      expect(info.latestBuildNumber, 6);
      expect(info.minRequiredVersion, '1.0.2');
      expect(info.minRequiredBuildNumber, 3);
      expect(info.downloadUrl, 'https://azure.blob/app.apk');
      expect(info.releaseNotes, 'Hotfix for payment cards');
      expect(info.forceUpdate, isTrue);

      final exported = info.toJson();
      expect(exported['latest_version'], '1.0.5');
      expect(exported['force_update'], isTrue);
    });
  });
}

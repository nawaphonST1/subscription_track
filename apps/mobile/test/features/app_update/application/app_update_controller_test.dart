import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/app_update/application/app_update_controller.dart';
import 'package:subscription_track/features/app_update/data/app_update_repository.dart';
import 'package:subscription_track/features/app_update/domain/app_update_info.dart';

void main() {
  group('AppUpdateController Unit Tests', () {
    test('initial state has default version and no updates pending', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(appUpdateControllerProvider);
      expect(state.currentVersion, '1.0.0');
      expect(state.currentBuildNumber, 1);
      expect(state.isUpdateAvailable, isFalse);
      expect(state.isForceUpdate, isFalse);
      expect(state.isChecking, isFalse);
    });

    test('checkForUpdates updates state when new version is available', () async {
      const mockInfo = AppUpdateInfo(
        latestVersion: '1.2.0',
        latestBuildNumber: 2,
        minRequiredVersion: '1.0.0',
        minRequiredBuildNumber: 1,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Performance improvements',
        forceUpdate: false,
      );

      final mockRepo = MockAppUpdateRepository(mockUpdateInfo: mockInfo);
      final container = ProviderContainer(
        overrides: [
          appUpdateRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(appUpdateControllerProvider.notifier);
      await controller.checkForUpdates();

      final state = container.read(appUpdateControllerProvider);
      expect(state.isChecking, isFalse);
      expect(state.isUpdateAvailable, isTrue);
      expect(state.isForceUpdate, isFalse);
      expect(state.updateInfo?.latestVersion, '1.2.0');
    });

    test('checkForUpdates sets forceUpdate flag when requirement is not met', () async {
      const mockForced = AppUpdateInfo(
        latestVersion: '2.0.0',
        latestBuildNumber: 10,
        minRequiredVersion: '2.0.0',
        minRequiredBuildNumber: 10,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Critical security fix',
        forceUpdate: true,
      );

      final mockRepo = MockAppUpdateRepository(mockUpdateInfo: mockForced);
      final container = ProviderContainer(
        overrides: [
          appUpdateRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(appUpdateControllerProvider.notifier);
      await controller.checkForUpdates();

      final state = container.read(appUpdateControllerProvider);
      expect(state.isUpdateAvailable, isTrue);
      expect(state.isForceUpdate, isTrue);
    });

    test('dismissUpdate dismisses optional update but refuses to dismiss force update', () async {
      const mockOptional = AppUpdateInfo(
        latestVersion: '1.1.0',
        latestBuildNumber: 2,
        minRequiredVersion: '1.0.0',
        minRequiredBuildNumber: 1,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Notes',
        forceUpdate: false,
      );

      final container = ProviderContainer(
        overrides: [
          appUpdateRepositoryProvider.overrideWithValue(
            MockAppUpdateRepository(mockUpdateInfo: mockOptional),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(appUpdateControllerProvider.notifier);
      await controller.checkForUpdates();
      expect(container.read(appUpdateControllerProvider).isUpdateAvailable, isTrue);

      controller.dismissUpdate();
      expect(container.read(appUpdateControllerProvider).isUpdateAvailable, isFalse);
    });

    test('simulateDownloadAndInstall updates progress correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(appUpdateControllerProvider.notifier);
      final downloadFuture = controller.simulateDownloadAndInstall();

      await downloadFuture;
      final state = container.read(appUpdateControllerProvider);
      expect(state.isDownloading, isFalse);
      expect(state.isDownloadCompleted, isTrue);
      expect(state.downloadProgress, 1.0);
    });
  });
}

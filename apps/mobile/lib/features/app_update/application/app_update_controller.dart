import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/app_update/data/app_update_repository.dart';
import 'package:subscription_track/features/app_update/domain/app_update_info.dart';

class AppUpdateState {
  const AppUpdateState({
    required this.currentVersion,
    required this.currentBuildNumber,
    this.updateInfo,
    this.isChecking = false,
    this.isUpdateAvailable = false,
    this.isForceUpdate = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isDownloadCompleted = false,
    this.errorMessage,
  });

  final String currentVersion;
  final int currentBuildNumber;
  final AppUpdateInfo? updateInfo;
  final bool isChecking;
  final bool isUpdateAvailable;
  final bool isForceUpdate;
  final bool isDownloading;
  final double downloadProgress;
  final bool isDownloadCompleted;
  final String? errorMessage;

  AppUpdateState copyWith({
    String? currentVersion,
    int? currentBuildNumber,
    AppUpdateInfo? updateInfo,
    bool? isChecking,
    bool? isUpdateAvailable,
    bool? isForceUpdate,
    bool? isDownloading,
    double? downloadProgress,
    bool? isDownloadCompleted,
    String? errorMessage,
  }) {
    return AppUpdateState(
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      updateInfo: updateInfo ?? this.updateInfo,
      isChecking: isChecking ?? this.isChecking,
      isUpdateAvailable: isUpdateAvailable ?? this.isUpdateAvailable,
      isForceUpdate: isForceUpdate ?? this.isForceUpdate,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloadCompleted: isDownloadCompleted ?? this.isDownloadCompleted,
      errorMessage: errorMessage,
    );
  }
}

class AppUpdateController extends Notifier<AppUpdateState> {
  @override
  AppUpdateState build() {
    return const AppUpdateState(
      currentVersion: '1.0.0',
      currentBuildNumber: 1,
    );
  }

  void setLocalVersion({required String version, required int buildNumber}) {
    state = state.copyWith(
      currentVersion: version,
      currentBuildNumber: buildNumber,
    );
  }

  Future<void> checkForUpdates({String? customManifestUrl}) async {
    state = state.copyWith(isChecking: true, errorMessage: null);

    try {
      final repository = ref.read(appUpdateRepositoryProvider);
      final info = await repository.fetchLatestVersionInfo(
        customManifestUrl: customManifestUrl,
      );

      if (info == null) {
        state = state.copyWith(
          isChecking: false,
          isUpdateAvailable: false,
          isForceUpdate: false,
        );
        return;
      }

      final available = info.isUpdateAvailable(
        state.currentBuildNumber,
        state.currentVersion,
      );
      final forced = info.isForceUpdateRequired(
        state.currentBuildNumber,
        state.currentVersion,
      );

      state = state.copyWith(
        isChecking: false,
        updateInfo: info,
        isUpdateAvailable: available,
        isForceUpdate: forced,
      );
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        errorMessage: e.toString(),
      );
    }
  }

  void dismissUpdate() {
    if (!state.isForceUpdate) {
      state = state.copyWith(isUpdateAvailable: false);
    }
  }

  Future<void> simulateDownloadAndInstall() async {
    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);

    for (var i = 1; i <= 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state = state.copyWith(downloadProgress: i / 10.0);
    }

    state = state.copyWith(
      isDownloading: false,
      isDownloadCompleted: true,
      downloadProgress: 1.0,
    );
  }
}

final appUpdateControllerProvider =
    NotifierProvider<AppUpdateController, AppUpdateState>(
  AppUpdateController.new,
);

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.minRequiredVersion,
    required this.minRequiredBuildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
  });

  final String latestVersion;
  final int latestBuildNumber;
  final String minRequiredVersion;
  final int minRequiredBuildNumber;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  /// Check whether an update is available comparing build numbers or semantic versions
  bool isUpdateAvailable(int currentBuildNumber, [String? currentVersion]) {
    if (latestBuildNumber > currentBuildNumber) {
      return true;
    }
    if (currentVersion != null) {
      return _compareSemVer(latestVersion, currentVersion) > 0;
    }
    return false;
  }

  /// Check whether force update is mandatory
  bool isForceUpdateRequired(int currentBuildNumber, [String? currentVersion]) {
    if (forceUpdate) return true;
    if (currentBuildNumber < minRequiredBuildNumber) return true;
    if (currentVersion != null) {
      return _compareSemVer(currentVersion, minRequiredVersion) < 0;
    }
    return false;
  }

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      latestBuildNumber: (json['latest_build_number'] as num?)?.toInt() ??
          (json['build_number'] as num?)?.toInt() ??
          1,
      minRequiredVersion: json['min_required_version'] as String? ?? '1.0.0',
      minRequiredBuildNumber:
          (json['min_required_build_number'] as num?)?.toInt() ?? 1,
      downloadUrl: json['download_url'] as String? ?? '',
      releaseNotes: json['release_notes'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'latest_build_number': latestBuildNumber,
      'min_required_version': minRequiredVersion,
      'min_required_build_number': minRequiredBuildNumber,
      'download_url': downloadUrl,
      'release_notes': releaseNotes,
      'force_update': forceUpdate,
    };
  }

  static int _compareSemVer(String v1, String v2) {
    final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (var i = 0; i < maxLen; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }
}

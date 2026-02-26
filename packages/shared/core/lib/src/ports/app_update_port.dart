import 'package:flutter/foundation.dart';

enum AppUpdateAvailability {
  upToDate,
  optionalUpdateAvailable,
  requiredUpdate,
  unsupportedPlatform,
  unavailable,
  failed,
}

@immutable
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.availability,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.minSupportedBuildNumber,
    required this.title,
    required this.message,
    this.updateUrl,
    this.releaseNotes,
  });

  final AppUpdateAvailability availability;
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final int minSupportedBuildNumber;
  final String title;
  final String message;
  final String? updateUrl;
  final String? releaseNotes;

  bool get hasUpdate =>
      availability == AppUpdateAvailability.optionalUpdateAvailable ||
      availability == AppUpdateAvailability.requiredUpdate;

  bool get isRequired => availability == AppUpdateAvailability.requiredUpdate;
}

abstract interface class AppUpdatePort {
  Future<AppUpdateInfo> checkForUpdate({bool forceRefresh = false});

  Future<bool> launchUpdate(AppUpdateInfo info);
}

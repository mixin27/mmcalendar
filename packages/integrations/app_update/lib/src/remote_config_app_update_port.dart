import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';

class RemoteConfigAppUpdatePort implements AppUpdatePort {
  RemoteConfigAppUpdatePort({
    required RemoteConfigPort remoteConfigPort,
    required String playStoreId,
    String? appStoreId,
    PackageInfo? packageInfo,
  }) : _remoteConfigPort = remoteConfigPort,
       _playStoreId = playStoreId,
       _appStoreId = appStoreId,
       _packageInfo = packageInfo;

  final RemoteConfigPort _remoteConfigPort;
  final String _playStoreId;
  final String? _appStoreId;
  final PackageInfo? _packageInfo;

  static const String _enabledKey = 'app_update_enabled';
  static const String _latestBuildNumberKey = 'app_update_latest_build_number';
  static const String _latestVersionKey = 'app_update_latest_version';
  static const String _minSupportedBuildNumberKey =
      'app_update_min_supported_build_number';
  static const String _forceTitleKey = 'app_update_force_title';
  static const String _forceMessageKey = 'app_update_force_message';
  static const String _optionalTitleKey = 'app_update_optional_title';
  static const String _optionalMessageKey = 'app_update_optional_message';
  static const String _releaseNotesKey = 'app_update_release_notes';
  static const String _androidUrlKey = 'app_update_android_url';
  static const String _iosUrlKey = 'app_update_ios_url';
  static const String _webUrlKey = 'app_update_web_url';

  @override
  Future<AppUpdateInfo> checkForUpdate({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        await _remoteConfigPort.fetchAndActivate();
      }

      if (kIsWeb) {
        return _buildUnsupportedInfo(currentVersion: 'web', buildNumber: 0);
      }

      final packageInfo = _packageInfo ?? await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = _toBuildNumber(packageInfo.buildNumber);
      final enabled = _remoteConfigPort.getBool(_enabledKey);

      if (!enabled) {
        return AppUpdateInfo(
          availability: AppUpdateAvailability.unavailable,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
          latestVersion: currentVersion,
          latestBuildNumber: currentBuild,
          minSupportedBuildNumber: 0,
          title: 'Updates are unavailable',
          message: 'Update checks are currently disabled.',
        );
      }

      final latestBuild = _remoteConfigPort.getInt(_latestBuildNumberKey);
      final minSupportedBuild = _remoteConfigPort.getInt(
        _minSupportedBuildNumberKey,
      );
      final latestVersion =
          _remoteConfigPort.getString(_latestVersionKey).trim().isEmpty
          ? currentVersion
          : _remoteConfigPort.getString(_latestVersionKey).trim();
      final releaseNotes = _remoteConfigPort.getString(_releaseNotesKey).trim();
      final updateUrl = _resolveUpdateUrl();
      final hasUpdateUrl = updateUrl.isNotEmpty;

      final isRequired =
          minSupportedBuild > 0 && currentBuild < minSupportedBuild;
      final hasOptionalUpdate = latestBuild > 0 && currentBuild < latestBuild;

      if ((isRequired || hasOptionalUpdate) && !hasUpdateUrl) {
        return AppUpdateInfo(
          availability: AppUpdateAvailability.failed,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
          latestVersion: latestVersion,
          latestBuildNumber: latestBuild,
          minSupportedBuildNumber: minSupportedBuild,
          title: 'Update configuration error',
          message:
              'Update is configured, but no update URL is available for this platform.',
        );
      }

      if (isRequired) {
        return AppUpdateInfo(
          availability: AppUpdateAvailability.requiredUpdate,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
          latestVersion: latestVersion,
          latestBuildNumber: latestBuild,
          minSupportedBuildNumber: minSupportedBuild,
          title: _stringOrDefault(_forceTitleKey, 'Update Required'),
          message: _stringOrDefault(
            _forceMessageKey,
            'A newer version is required to continue using the app.',
          ),
          updateUrl: updateUrl,
          releaseNotes: releaseNotes.isEmpty ? null : releaseNotes,
        );
      }

      if (hasOptionalUpdate) {
        return AppUpdateInfo(
          availability: AppUpdateAvailability.optionalUpdateAvailable,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuild,
          latestVersion: latestVersion,
          latestBuildNumber: latestBuild,
          minSupportedBuildNumber: minSupportedBuild,
          title: _stringOrDefault(_optionalTitleKey, 'Update Available'),
          message: _stringOrDefault(
            _optionalMessageKey,
            'A newer version is available.',
          ),
          updateUrl: updateUrl,
          releaseNotes: releaseNotes.isEmpty ? null : releaseNotes,
        );
      }

      return AppUpdateInfo(
        availability: AppUpdateAvailability.upToDate,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuild,
        minSupportedBuildNumber: minSupportedBuild,
        title: 'Up to date',
        message: 'You are already using the latest version.',
      );
    } catch (error) {
      debugPrint('Failed to check app update: $error');
      return const AppUpdateInfo(
        availability: AppUpdateAvailability.failed,
        currentVersion: 'unknown',
        currentBuildNumber: 0,
        latestVersion: 'unknown',
        latestBuildNumber: 0,
        minSupportedBuildNumber: 0,
        title: 'Update check failed',
        message: 'Unable to check for updates right now.',
      );
    }
  }

  @override
  Future<bool> launchUpdate(AppUpdateInfo info) async {
    final url = info.updateUrl;
    if (url == null || url.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        return false;
      }
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('Failed to launch update URL: $error');
      return false;
    }
  }

  String _resolveUpdateUrl() {
    if (kIsWeb) {
      return _remoteConfigPort.getString(_webUrlKey).trim();
    }

    if (Platform.isAndroid) {
      final configured = _remoteConfigPort.getString(_androidUrlKey).trim();
      if (configured.isNotEmpty) {
        return configured;
      }
      return 'https://play.google.com/store/apps/details?id=$_playStoreId';
    }

    if (Platform.isIOS) {
      final configured = _remoteConfigPort.getString(_iosUrlKey).trim();
      if (configured.isNotEmpty) {
        return configured;
      }
      if (_appStoreId != null && _appStoreId.isNotEmpty) {
        return 'https://apps.apple.com/app/id$_appStoreId';
      }
      return '';
    }

    return '';
  }

  int _toBuildNumber(String rawBuildNumber) {
    final parsed = int.tryParse(rawBuildNumber);
    if (parsed != null) {
      return parsed;
    }

    final normalized = rawBuildNumber.split('+').last.trim();
    return int.tryParse(normalized) ?? 0;
  }

  String _stringOrDefault(String key, String fallback) {
    final value = _remoteConfigPort.getString(key).trim();
    return value.isEmpty ? fallback : value;
  }

  AppUpdateInfo _buildUnsupportedInfo({
    required String currentVersion,
    required int buildNumber,
  }) {
    return AppUpdateInfo(
      availability: AppUpdateAvailability.unsupportedPlatform,
      currentVersion: currentVersion,
      currentBuildNumber: buildNumber,
      latestVersion: currentVersion,
      latestBuildNumber: buildNumber,
      minSupportedBuildNumber: 0,
      title: 'Unsupported platform',
      message: 'App update checks are not available on this platform.',
    );
  }
}

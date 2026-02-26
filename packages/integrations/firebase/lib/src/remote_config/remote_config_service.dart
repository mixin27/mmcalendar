import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

class RemoteConfigService implements RemoteConfigPort {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigFetchStatus get lastFetchStatus => _remoteConfig.lastFetchStatus;

  @override
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 12),
        ),
      );
      await fetchAndActivate();
    } catch (e) {
      // Known issue on macOS: Firebase Installations can't access keychain in debug/simulator
      // This doesn't affect functionality, just prevents token persistence
      if (!kIsWeb && Platform.isMacOS && e.toString().contains('SecItemAdd')) {
        debugPrint(
          '⚠️ Remote Config: macOS keychain access denied (known simulator limitation). '
          'Remote Config will still work but tokens won\'t persist.',
        );
      } else {
        debugPrint('Failed to initialize Remote Config: $e');
      }
    }
  }

  @override
  Future<RemoteFetchResult> fetchAndActivate() async {
    try {
      final activated = await _remoteConfig.fetchAndActivate();
      if (!activated &&
          _remoteConfig.lastFetchStatus == RemoteConfigFetchStatus.success) {
        return RemoteFetchResult.noChange;
      }

      return activated
          ? RemoteFetchResult.activated
          : RemoteFetchResult.noChange;
    } catch (e) {
      debugPrint('Failed to fetch and activate Remote Config: $e');
      return RemoteFetchResult.failed;
    }
  }

  @override
  String getString(String key) => _remoteConfig.getString(key);
  @override
  bool getBool(String key) => _remoteConfig.getBool(key);
  @override
  int getInt(String key) => _remoteConfig.getInt(key);
  @override
  double getDouble(String key) => _remoteConfig.getDouble(key);

  @override
  Map<String, Object> getAll() {
    return _remoteConfig.getAll().map(
      (key, value) => MapEntry<String, Object>(key, value.asString()),
    );
  }
}

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

enum RemoteFetchResult { activated, noChange, failed }

class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigFetchStatus get lastFetchStatus => _remoteConfig.lastFetchStatus;

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
      debugPrint('Failed to initialize Remote Config: $e');
    }
  }

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

  String getString(String key) => _remoteConfig.getString(key);
  bool getBool(String key) => _remoteConfig.getBool(key);
  int getInt(String key) => _remoteConfig.getInt(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);

  Map<String, RemoteConfigValue> getAll() => _remoteConfig.getAll();
}

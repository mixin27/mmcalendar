import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppRemoteConfig {
  static final _config = FirebaseRemoteConfig.instance;

  static final _defaultValues = {
    "show_ads": true,
  };

  static Future<void> initConfig() async {
    await _config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 30),
      ),
    );

    await _config.setDefaults(_defaultValues);
    await _config.fetchAndActivate();

    log('remoteConfigData: ${_config.getString("show_ads")}');

    _config.onConfigUpdated.listen((event) async {
      await _config.activate();
      log('updated: ${_config.getBool("show_ads")}');
    });
  }

  static String get updateTitle => _config.getString("update_title");
  static String get updateDescription =>
      _config.getString("update_description");

  // static String get apiUrl => _config.getString("api_url");
  // static String get apiKey => _config.getString("api_key");

  static bool get _showAds => _config.getBool('show_ads');
  static bool get hideAds => !_showAds;
}

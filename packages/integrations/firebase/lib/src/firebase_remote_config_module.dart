import 'package:app_remote_config/app_remote_config.dart';

/// Composition helper for Firebase Remote Config setup.
final class FirebaseRemoteConfigModule {
  const FirebaseRemoteConfigModule._();

  static Future<RemoteConfigService> initialize({
    RemoteConfigService? service,
  }) async {
    final remoteConfig = service ?? RemoteConfigService();
    await remoteConfig.initialize();
    return remoteConfig;
  }
}

/// The installed app's version, read once at startup from the platform.
class AppVersionInfo {
  const AppVersionInfo({required this.version, this.buildNumber = 0});

  /// "2.3.0".
  final String version;
  final int buildNumber;
}

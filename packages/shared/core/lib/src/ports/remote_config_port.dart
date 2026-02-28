enum RemoteFetchResult { activated, noChange, failed }

/// SDK-agnostic remote config contract used by feature packages.
abstract interface class RemoteConfigPort {
  Future<void> initialize();

  Future<RemoteFetchResult> fetchAndActivate();

  String getString(String key);

  bool getBool(String key);

  int getInt(String key);

  double getDouble(String key);

  Map<String, Object> getAll();
}

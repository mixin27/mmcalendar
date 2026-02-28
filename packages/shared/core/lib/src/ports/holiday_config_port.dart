/// SDK-agnostic contract for loading holiday configuration payloads.
///
/// Concrete integrations are responsible for retrieving and decoding the
/// configuration source (for example, Firebase Remote Config JSON).
abstract interface class HolidayConfigPort {
  /// Returns a decoded holiday configuration map.
  ///
  /// Implementations should return an empty map when config is unavailable
  /// or invalid.
  Map<String, dynamic> getHolidayConfig();
}

/// SDK-agnostic contract for reading display preferences used across features.
abstract interface class DisplayPreferencesPort {
  /// Current user preference for rendering Shan calendar details.
  Future<bool> getShowShanCalendar();

  /// Reactive stream for Shan calendar visibility preference updates.
  Stream<bool> watchShowShanCalendar();
}

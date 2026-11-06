/// Day notes for features that show them without depending on the notes
/// feature (the home-screen widgets).
abstract interface class DayNotesPort {
  /// The notes on days from [from] to [to], both included, as each day's
  /// short preview, as they change.
  Stream<Map<DateTime, String>> watchNotePreviews(DateTime from, DateTime to);
}

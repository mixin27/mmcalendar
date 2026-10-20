import 'dart:async';

import 'package:shared_core/shared_core.dart';

/// Settings › Prefer Shan Year, kept current so the converter can format
/// dates synchronously. On (the setting's default) until the port says
/// otherwise, or always without one.
class ShanYearPreference {
  ShanYearPreference([DisplayPreferencesPort? port]) {
    _subscription = port?.watchShowShanCalendar().listen((v) => value = v);
  }

  bool value = true;
  StreamSubscription<bool>? _subscription;

  void dispose() => _subscription?.cancel();
}

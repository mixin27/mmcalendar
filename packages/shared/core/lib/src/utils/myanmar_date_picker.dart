import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart' as mm;
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import 'myanmar_calendar_runtime.dart';

/// Gives flutter_mmcalendar widgets the app's calendar settings: the global
/// configuration (time zone, custom and disabled holidays), the calendar
/// language and the app's style.
///
/// Put it once near the root, below `MaterialApp` so it sees the theme.
class AppMyanmarCalendarScope extends StatelessWidget {
  const AppMyanmarCalendarScope({
    super.key,
    required this.language,
    required this.clearStyle,
    required this.child,
  });

  /// The calendar language.
  final Language language;

  /// Whether the app uses its Clear (iOS-like) style; Material otherwise.
  final bool clearStyle;

  final Widget child;

  static MyanmarCalendarClient? _client;
  static int _clientGeneration = -1;

  /// A client on the global configuration, rebuilt whenever
  /// [applyMyanmarCalendarRuntimeConfig] changes it.
  static MyanmarCalendarClient get client {
    if (_client == null ||
        _clientGeneration != myanmarCalendarConfigGeneration) {
      _client = MyanmarCalendarClient(
        config: MyanmarCalendar.config,
        useGlobalCache: true,
      );
      _clientGeneration = myanmarCalendarConfigGeneration;
    }
    return _client!;
  }

  @override
  Widget build(BuildContext context) {
    return mm.MyanmarCalendarScope(
      client: client,
      language: language,
      // The app's Clear style is its iOS look; it has no glass.
      style: clearStyle
          ? mm.MmVisualStyle.cupertino
          : mm.MmVisualStyle.material,
      child: child,
    );
  }
}

/// Shows the Myanmar date picker in the app's style and returns the chosen
/// day, or `null` if the user cancels.
Future<DateTime?> showAppMyanmarDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  // The root navigator, so the sheet covers the tab bar instead of sitting
  // under it. It is below [AppMyanmarCalendarScope], which wraps the router.
  final selected = await mm.showMyanmarDatePicker(
    context: Navigator.of(context, rootNavigator: true).context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (selected == null) return null;
  final w = selected.western;
  return DateTime(w.year, w.month, w.day);
}

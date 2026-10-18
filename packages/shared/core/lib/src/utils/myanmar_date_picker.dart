import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart' as mm;
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import 'myanmar_calendar_runtime.dart';

/// The app's design colours that flutter_mmcalendar widgets use. Plain
/// colours, so this package needn't depend on the UI kit; the app fills it
/// from its design tokens.
@immutable
class AppCalendarColors {
  const AppCalendarColors({
    required this.brightness,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.surface,
    required this.fill,
    required this.label,
    required this.secondaryLabel,
    required this.separator,
    required this.holiday,
    required this.sabbath,
    required this.moon,
  });

  final Brightness brightness;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color surface;
  final Color fill;
  final Color label;
  final Color secondaryLabel;
  final Color separator;
  final Color holiday;
  final Color sabbath;
  final Color moon;

  /// The package theme in these colours. Religious, cultural and other
  /// holiday colours keep the package's; anniversaries use the app grid's
  /// teal.
  mm.MmCalendarThemeData toTheme() {
    final dark = brightness == Brightness.dark;
    final base = mm.MmCalendarThemeData.fromColorScheme(
      ColorScheme.fromSeed(seedColor: accent, brightness: brightness),
    );
    return base.copyWith(
      accent: accent,
      onAccent: onAccent,
      accentContainer: accentSoft,
      surface: surface,
      surfaceVariant: fill,
      ink: label,
      muted: secondaryLabel,
      outline: separator,
      outside: label.withValues(alpha: .35),
      publicHoliday: holiday,
      anniversary: dark ? const Color(0xFF3CC6C2) : const Color(0xFF0E8C88),
      sabbath: sabbath,
      moon: moon,
      moonShadow: Color.lerp(surface, label, dark ? .22 : .14),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppCalendarColors &&
      other.brightness == brightness &&
      other.accent == accent &&
      other.onAccent == onAccent &&
      other.accentSoft == accentSoft &&
      other.surface == surface &&
      other.fill == fill &&
      other.label == label &&
      other.secondaryLabel == secondaryLabel &&
      other.separator == separator &&
      other.holiday == holiday &&
      other.sabbath == sabbath &&
      other.moon == moon;

  @override
  int get hashCode => Object.hash(
    brightness,
    accent,
    onAccent,
    accentSoft,
    surface,
    fill,
    label,
    secondaryLabel,
    separator,
    holiday,
    sabbath,
    moon,
  );
}

/// Gives flutter_mmcalendar widgets the app's calendar settings: the global
/// configuration (time zone, custom and disabled holidays), the calendar
/// language, week start, style and colours.
///
/// Put it once near the root, below `MaterialApp` so it sees the theme.
class AppMyanmarCalendarScope extends StatelessWidget {
  const AppMyanmarCalendarScope({
    super.key,
    required this.language,
    required this.clearStyle,
    required this.child,
    this.colors,
    this.firstDayOfWeek = DateTime.sunday,
  });

  /// The calendar language.
  final Language language;

  /// Whether the app uses its Clear (iOS-like) style; Material otherwise.
  final bool clearStyle;

  /// The app's colours; the app's `ColorScheme` is used when null.
  final AppCalendarColors? colors;

  /// The first column's weekday, as a `DateTime` weekday.
  final int firstDayOfWeek;

  /// The `DateTime` weekday for the app's Myanmar weekday index (0 is
  /// Saturday, 1 Sunday...), as the week-start setting stores it.
  static int weekdayFromMyanmarIndex(int index) => (index + 5) % 7 + 1;

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
      theme: colors?.toTheme(),
      firstDayOfWeek: firstDayOfWeek,
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

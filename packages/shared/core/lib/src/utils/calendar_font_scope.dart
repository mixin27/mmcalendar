import 'package:flutter/widgets.dart';

/// Builds the font fields (family, fallback, variable weight) for a display
/// family name, e.g. `Fraunces`.
typedef CalendarFontResolver =
    TextStyle Function(String family, FontWeight weight);

/// Lets the calendar draw numbers in the display typefaces another package
/// bundles (Calendar Studio's), without depending on it. The app provides it
/// near the root; without one, numbers keep the app's font.
class CalendarFontScope extends InheritedWidget {
  const CalendarFontScope({
    super.key,
    required this.resolve,
    required super.child,
  });

  final CalendarFontResolver resolve;

  static CalendarFontResolver? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CalendarFontScope>()?.resolve;

  @override
  bool updateShouldNotify(CalendarFontScope oldWidget) =>
      resolve != oldWidget.resolve;
}

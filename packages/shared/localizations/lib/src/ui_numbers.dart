import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Numbers inside interface text ("in 3 days", "100% lit") follow the app
/// language, like the words around them: Myanmar digits in the Myanmar
/// interface. Calendar data uses the calendar language instead
/// (`CalendarFormat` in shared_core).
extension UiNumbers on BuildContext {
  /// [value] in the app language's digits, without grouping ("2027").
  String uiNumber(num value) => NumberFormat(
    '0',
    Localizations.localeOf(this).toLanguageTag(),
  ).format(value);
}

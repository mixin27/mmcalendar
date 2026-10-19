import 'package:shared_core/shared_core.dart';

/// Links the widgets open, as `mmcalendar://…` URIs, and where each one
/// goes in the app.
///
/// - `mmcalendar://today` → home
/// - `mmcalendar://day/2026-10-18` → that day's details
/// - `mmcalendar://month/2026-10` → home on that month
/// - `mmcalendar://event/12` → the event
/// - `mmcalendar://events/new?date=2026-10-18` → a new event on that day
/// - `mmcalendar://events` → the events list
abstract final class WidgetLinks {
  static const scheme = 'mmcalendar';

  /// The go_router location for [uri], or null when it isn't a widget link.
  static String? locationFor(Uri? uri) {
    if (uri == null || uri.scheme != scheme) return null;
    final segments = [uri.host, ...uri.pathSegments].where((s) => s.isNotEmpty);
    final parts = segments.toList();
    if (parts.isEmpty) return RoutePaths.home;
    switch (parts.first) {
      case 'today':
        return RoutePaths.home;
      case 'day' when parts.length > 1 && _date(parts[1]) != null:
        return '${RoutePaths.home}/${RoutePaths.dayDetails}?date=${parts[1]}';
      case 'month' when parts.length > 1:
        final month = DateTime.tryParse('${parts[1]}-01');
        return month == null
            ? RoutePaths.home
            : '${RoutePaths.home}?date=${parts[1]}-01';
      case 'event' when parts.length > 1 && int.tryParse(parts[1]) != null:
        return RoutePaths.eventsDetail(int.parse(parts[1]));
      case 'events' when parts.length > 1 && parts[1] == 'new':
        final date = uri.queryParameters['date'];
        return _date(date) == null
            ? RoutePaths.eventsCreate()
            : '${RoutePaths.eventsCreate()}?date=$date';
      case 'events':
        return RoutePaths.events;
    }
    return RoutePaths.home;
  }

  static DateTime? _date(String? value) =>
      value == null ? null : DateTime.tryParse(value);
}

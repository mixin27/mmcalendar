import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart' as mm;
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/views_injection.dart';

/// The next 90 days that have something on them: holidays, anniversaries,
/// Sabbath, full and new moons, and the user's events, under a header per
/// month. Tapping a day opens its details; tapping an event opens the event.
class AgendaViewPage extends StatefulWidget {
  const AgendaViewPage({super.key, this.days = 90});

  /// How many days ahead to list.
  final int days;

  @override
  State<AgendaViewPage> createState() => _AgendaViewPageState();
}

class _AgendaViewPageState extends State<AgendaViewPage> {
  final AnalyticsPort _analytics = getIt<AnalyticsPort>();
  late final DateTime _from = DateUtils.dateOnly(DateTime.now());
  Map<DateTime, List<CalendarEventItem>> _events = const {};
  StreamSubscription<Map<DateTime, List<CalendarEventItem>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(
      screenName: 'agenda_view',
      screenClass: 'AgendaViewPage',
    );
    if (getIt.isRegistered<EventMarkersPort>()) {
      _subscription = getIt<EventMarkersPort>()
          .watchEventMarkers(
            startDate: _from,
            endDate: _from.add(Duration(days: widget.days)),
          )
          .listen((events) {
            if (mounted) setState(() => _events = events);
          });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<Object?> _load(DateTime day) =>
      _events[DateUtils.dateOnly(day)] ?? const [];

  void _openDay(mm.CompleteDate day) {
    final w = day.western;
    context.go(
      '${RoutePaths.views}/${RoutePaths.dayView}',
      extra: DateTime(w.year, w.month, w.day),
    );
  }

  Widget _event(BuildContext context, Object? item) {
    final event = item! as CalendarEventItem;
    final t = context.tokens;
    final color = Color(event.effectiveColor);
    final time = event.isAllDay || event.eventTime == null
        ? null
        : TimeOfDay.fromDateTime(event.eventTime!).format(context);
    final id = event.id;
    return Semantics(
      button: id != null,
      child: InkWell(
        borderRadius: BorderRadius.circular(t.controlRadius),
        onTap: id == null || !getIt.isRegistered<EventActionsPort>()
            ? null
            : () => getIt<EventActionsPort>().openEventDetail(
                context,
                eventId: id,
                occurrenceDate: event.eventDate,
              ),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(t.controlRadius),
            border: BorderDirectional(
              start: BorderSide(color: color, width: 3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.label,
                    decoration: event.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              if (time != null)
                Text(time, style: TextStyle(color: t.secondaryLabel)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n?.viewsAgenda ?? 'Agenda',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: mm.MyanmarAgendaSliver(
            key: const ValueKey('views-agenda'),
            from: _from,
            to: _from.add(Duration(days: widget.days - 1)),
            eventLoader: _load,
            eventBuilder: _event,
            onDayTapped: _openDay,
          ),
        ),
      ],
    );
  }
}

import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart'
    show CalendarLanguageContext, Failure, MyanmarRecurrence, RoutePaths;
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' hide ContextExtension;

import '../../application/services/event_flow_service.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/repositories/events_repository.dart';
import '../../domain/services/event_share.dart';
import '../widgets/repeat_sheet.dart';

/// Saves a new event; its id, or null when it couldn't be saved.
typedef SaveSharedEvent = Future<int?> Function(Event event);

/// What a shared event link opens: the event, and "Add to my calendar".
class SharedEventPage extends StatefulWidget {
  const SharedEventPage({
    super.key,
    required this.data,
    this.save,
    this.categories,
  });

  /// The link's data (`e=`).
  final String? data;

  /// Saves the event; the app's event flow when null.
  final SaveSharedEvent? save;

  /// The receiver's categories; the app's when null.
  final Future<List<EventCategory>> Function()? categories;

  @override
  State<SharedEventPage> createState() => _SharedEventPageState();
}

class _SharedEventPageState extends State<SharedEventPage> {
  late final SharedEvent? _event = EventShare.decode(widget.data);
  bool _saving = false;

  Future<List<EventCategory>> _categories() async {
    if (widget.categories case final load?) return load();
    final Either<Failure, List<EventCategory>> result =
        await GetIt.instance<EventsRepository>().getAllCategories();
    return result.fold((_) => const [], (c) => c);
  }

  Future<int?> _save(Event event) async {
    if (widget.save case final save?) return save(event);
    final result = await GetIt.instance<EventFlowService>().saveEvent(event);
    return result.fold((_) => null, (r) => r.event.id);
  }

  Future<void> _add() async {
    final shared = _event;
    if (shared == null || _saving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    int? id;
    try {
      final categories = await _categories();
      final fallback =
          categories.where((c) => c.name == 'Personal').firstOrNull ??
          categories.firstOrNull ??
          EventCategory.personal;
      id = await _save(
        shared.toEvent(category: fallback, categories: categories),
      );
    } on Object catch (e) {
      debugPrint('Adding a shared event failed: $e');
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (id == null) {
      context.showToast(l10n.sharedEventFailed, kind: AppToastKind.error);
      return;
    }
    context.showToast(l10n.sharedEventAdded, kind: AppToastKind.success);
    GoRouter.of(context).go(RoutePaths.eventsDetail(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    final event = _event;
    if (event == null) {
      return AppPage(
        title: l10n.sharedEventTitle,
        largeTitle: false,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Column(
              key: const ValueKey('shared-event-invalid'),
              children: [
                Icon(Icons.link_off_rounded, size: 44, color: t.tertiaryLabel),
                const SizedBox(height: 12),
                Text(
                  l10n.sharedEventInvalid,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.label,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.sharedEventInvalidMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.secondaryLabel, fontSize: 15),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: l10n.goBack,
                  onPressed: () => GoRouter.of(context).go(RoutePaths.home),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final format = context.calendarFormat;
    final time = event.time;
    final myanmar = format.myanmar(
      MyanmarRecurrence.myanmarOf(event.date),
      '&y &M &P &f',
    );
    final rule = event.recurrence;
    return AppPage(
      title: l10n.sharedEventTitle,
      largeTitle: false,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  key: const ValueKey('shared-event-name'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${format.fullDate(event.date)} · '
                  '${time == null ? l10n.allDay : TimeOfDay.fromDateTime(time).format(context)}',
                  style: TextStyle(color: t.secondaryLabel),
                ),
                Text(myanmar, style: TextStyle(color: t.secondaryLabel)),
              ],
            ),
          ),
        ),
        if (event.description case final notes?)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SelectableText(
                notes,
                style: const TextStyle(fontSize: 15, height: 1.55),
              ),
            ),
          ),
        AppGroup(
          footer: l10n.sharedEventFooter,
          children: [
            if (rule != null)
              AppRow(
                key: const ValueKey('shared-event-repeat'),
                icon: Icons.repeat,
                iconColor: const Color(0xFF8E8E93),
                title: l10n.repeat,
                subtitle:
                    myanmarRepeatDay(context, rule.type, event.date) ??
                    repeatSummary(context, rule),
              ),
            if (event.location case final place?)
              AppRow(
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFF1F9D63),
                title: l10n.location,
                subtitle: place,
              ),
            if (event.categoryName case final category?)
              AppRow(
                icon: Icons.sell_outlined,
                iconColor: const Color(0xFF8E6CEF),
                title: l10n.category,
                value: category,
              ),
          ],
        ),
        AppButton(
          key: const ValueKey('shared-event-add'),
          label: l10n.sharedEventAdd,
          icon: Icons.add_rounded,
          onPressed: _saving ? null : _add,
        ),
      ],
    );
  }
}

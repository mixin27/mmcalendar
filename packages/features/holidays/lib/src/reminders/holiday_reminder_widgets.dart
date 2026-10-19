import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../catalog/holiday_catalog.dart';
import '../domain/holiday_year.dart';
import 'holiday_reminders.dart';

/// The app's [HolidayReminders], when registered.
HolidayReminders? get holidayReminders =>
    GetIt.instance.isRegistered<HolidayReminders>()
    ? GetIt.instance<HolidayReminders>()
    : null;

String _timeText(AppLocalizations l10n, HolidayReminderTime time) =>
    switch (time) {
      HolidayReminderTime.evening => l10n.holidayReminderEvening,
      HolidayReminderTime.morning => l10n.holidayReminderMorning,
      HolidayReminderTime.both => l10n.holidayReminderBoth,
    };

void _deniedToast(BuildContext context, bool granted) {
  if (!granted && context.mounted) {
    context.showToast(
      AppLocalizations.of(context)!.holidayRemindersPermissionDenied,
      kind: AppToastKind.error,
    );
  }
}

/// "Remind me" for one holiday, with the reminder time; tapping the row
/// opens the reminder options.
class HolidayReminderGroup extends StatelessWidget {
  const HolidayReminderGroup({super.key, required this.entry});

  final HolidayEntry entry;

  @override
  Widget build(BuildContext context) {
    final reminders = holidayReminders;
    if (reminders == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    return ListenableBuilder(
      listenable: reminders,
      builder: (context, _) {
        final covered = reminders.coveredByAllPublic(entry);
        final on = reminders.isOn(entry);
        return AppGroup(
          children: [
            AppRow(
              key: const ValueKey('holiday-remind-me'),
              icon: Icons.notifications_outlined,
              iconColor: t.moon,
              title: l10n.holidayRemindMe,
              subtitle: covered
                  ? l10n.holidayRemindersIncluded
                  : on
                  ? _timeText(l10n, reminders.time)
                  : null,
              trailing: AppSwitch(
                value: on,
                onChanged: covered
                    ? null
                    : (v) async {
                        final granted = await reminders.follow(entry, v);
                        if (context.mounted) {
                          _deniedToast(context, granted);
                        }
                      },
              ),
              onTap: () => showHolidayReminderSheet(context),
            ),
          ],
        );
      },
    );
  }
}

/// When reminders come, and following all public holidays.
Future<void> showHolidayReminderSheet(BuildContext context) async {
  final reminders = holidayReminders;
  if (reminders == null) return;
  final l10n = AppLocalizations.of(context)!;
  final year = DateTime.now().year;
  await showAppSheet<void>(
    context: context,
    title: l10n.holidayRemindersTitle,
    cancelLabel: MaterialLocalizations.of(context).closeButtonLabel,
    builder: (sheetContext) => ListenableBuilder(
      listenable: reminders,
      builder: (sheetContext, _) {
        final publicCount = HolidayYears.of(
          year,
          sheetContext.calendarLanguage,
        ).where((o) => o.entry.officeClosed).length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppGroup(
              label: l10n.holidayRemindersWhen,
              children: [
                for (final (time, label) in [
                  (
                    HolidayReminderTime.evening,
                    l10n.holidayRemindersEveningOption,
                  ),
                  (
                    HolidayReminderTime.morning,
                    l10n.holidayRemindersMorningOption,
                  ),
                  (HolidayReminderTime.both, l10n.holidayRemindersBothOption),
                ])
                  AppRow(
                    key: ValueKey('holiday-reminder-time-${time.name}'),
                    title: label,
                    subtitle: time == HolidayReminderTime.both
                        ? null
                        : _timeText(l10n, time),
                    selected: reminders.time == time,
                    onTap: () => reminders.setTime(time),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            AppGroup(
              label: l10n.holidayRemindersFollow,
              footer: l10n.holidayRemindersFooter,
              children: [
                AppRow.toggle(
                  key: const ValueKey('holiday-reminder-all-public'),
                  icon: Icons.star_rounded,
                  iconColor: sheetContext.tokens.holiday,
                  title: l10n.holidayRemindersAllPublic,
                  subtitle: l10n.holidayRemindersAllPublicSubtitle(
                    publicCount,
                    '$year',
                  ),
                  value: reminders.allPublic,
                  onChanged: (v) async {
                    final granted = await reminders.setAllPublic(v);
                    if (sheetContext.mounted) {
                      _deniedToast(sheetContext, granted);
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

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

/// "Remind me of Sabbath days", for a Sabbath day's details; tapping the
/// row opens the reminder options.
class SabbathReminderGroup extends StatelessWidget {
  const SabbathReminderGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = holidayReminders;
    if (reminders == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: reminders,
      builder: (context, _) => AppGroup(
        children: [
          AppRow(
            key: const ValueKey('sabbath-remind-me'),
            icon: Icons.notifications_outlined,
            iconColor: context.tokens.moon,
            title: l10n.sabbathRemindMe,
            subtitle: reminders.sabbath
                ? _timeText(l10n, reminders.time)
                : null,
            trailing: AppSwitch(
              value: reminders.sabbath,
              onChanged: (v) async {
                final granted = await reminders.setSabbath(v);
                if (context.mounted) _deniedToast(context, granted);
              },
            ),
            onTap: () => showHolidayReminderSheet(context),
          ),
        ],
      ),
    );
  }
}

/// When reminders come, following all public holidays, and Sabbath days.
Future<void> showHolidayReminderSheet(BuildContext context) async {
  final reminders = holidayReminders;
  if (reminders == null) return;
  final l10n = AppLocalizations.of(context)!;
  final year = DateTime.now().year;
  await showAppSheet<void>(
    context: context,
    title: l10n.holidayRemindersTitle,
    cancelLabel: MaterialLocalizations.of(context).closeButtonLabel,
    // Above the tab bar, so the whole sheet shows.
    useRootNavigator: true,
    builder: (sheetContext) => ListenableBuilder(
      listenable: reminders,
      builder: (sheetContext, _) {
        final publicCount = HolidayYears.of(
          year,
          sheetContext.calendarLanguage,
        ).where((o) => o.entry.officeClosed).length;
        // Scrolls on short screens.
        return SingleChildScrollView(
          child: Column(
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
                  AppRow.toggle(
                    key: const ValueKey('holiday-reminder-sabbath'),
                    icon: Icons.self_improvement_rounded,
                    iconColor: sheetContext.tokens.moon,
                    title: l10n.holidayRemindersSabbath,
                    subtitle: l10n.holidayRemindersSabbathSubtitle,
                    value: reminders.sabbath,
                    onChanged: (v) async {
                      final granted = await reminders.setSabbath(v);
                      if (sheetContext.mounted) {
                        _deniedToast(sheetContext, granted);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),
              AppGroup(
                footer: l10n.dailySummaryFooter,
                children: [
                  AppRow.toggle(
                    key: const ValueKey('holiday-reminder-daily'),
                    icon: Icons.wb_twilight_rounded,
                    iconColor: sheetContext.tokens.accent,
                    title: l10n.dailySummary,
                    subtitle: l10n.dailySummarySubtitle,
                    value: reminders.daily,
                    onChanged: (v) async {
                      final granted = await reminders.setDaily(v);
                      if (sheetContext.mounted) {
                        _deniedToast(sheetContext, granted);
                      }
                    },
                  ),
                  if (reminders.daily)
                    AppRow(
                      key: const ValueKey('holiday-reminder-daily-time'),
                      title: l10n.dailySummaryTime,
                      value: TimeOfDay(
                        hour: reminders.dailyHour,
                        minute: 0,
                      ).format(sheetContext),
                      chevron: true,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: TimeOfDay(
                            hour: reminders.dailyHour,
                            minute: 0,
                          ),
                        );
                        if (picked != null) {
                          await reminders.setDailyHour(picked.hour);
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

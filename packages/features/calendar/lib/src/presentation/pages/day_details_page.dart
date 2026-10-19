import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/calendar_injection.dart';
import '../widgets/astro_phrases.dart';
import '../widgets/day_details_content.dart';

class DayDetailsPage extends StatefulWidget {
  final DateTime date;

  const DayDetailsPage({super.key, required this.date});

  @override
  State<DayDetailsPage> createState() => _DayDetailsPageState();
}

class _DayDetailsPageState extends State<DayDetailsPage>
    with SingleTickerProviderStateMixin {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final DisplayPreferencesPort _displayPreferencesPort =
      getIt<DisplayPreferencesPort>();
  final EventActionsPort _eventActionsPort = getIt<EventActionsPort>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late CompleteDate _completeDate;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();

    _analyticsService.logScreenView(
      screenName: 'day_details',
      screenClass: 'DayDetailsPage',
    );

    _analyticsService.logDateSelection(
      selectedDate: widget.date.toString(),
      calendarType: 'myanmar',
      dateFormat: 'detailed_view',
    );

    _currentDate = widget.date;
    _completeDate = MyanmarCalendar.getCompleteDate(widget.date);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  void _navigateToDay(DateTime newDate) {
    setState(() {
      _currentDate = newDate;
      _completeDate = MyanmarCalendar.getCompleteDate(_currentDate);
    });

    _animationController
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _step(int days, String button) {
    _analyticsService.logButtonClick(
      buttonName: button,
      buttonLocation: 'day_details_appbar',
    );
    HapticFeedback.lightImpact();
    _navigateToDay(_currentDate.add(Duration(days: days)));
  }

  String _relativeLabel(AppLocalizations? l10n) {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = DateUtils.dateOnly(_currentDate).difference(today).inDays;
    return switch (days) {
      0 => l10n?.today ?? 'Today',
      1 => l10n?.tomorrow ?? 'Tomorrow',
      -1 => l10n?.yesterday ?? 'Yesterday',
      > 1 => l10n?.calendarDaysFromToday(days) ?? '$days days from today',
      _ => l10n?.calendarDaysAgo(-days) ?? '${-days} days ago',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity == 0) return;
        final next = velocity < 0;
        final target = _currentDate.add(Duration(days: next ? 1 : -1));
        _analyticsService.logWidgetInteraction(
          widgetName: 'day_details_page',
          actionType: next ? 'swipe_next' : 'swipe_previous',
          metadata: {
            'from_date': _currentDate.toString(),
            'to_date': target.toString(),
          },
        );
        _navigateToDay(target);
      },
      child: StreamBuilder<bool>(
        stream: _displayPreferencesPort.watchShowShanCalendar(),
        initialData: true,
        builder: (context, snapshot) {
          final showShanCalendar = snapshot.data ?? true;
          return AppPage(
            title: context.calendarFormat.shortDate(_currentDate),
            actions: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: l10n?.dayDetailsPreviousDay ?? 'Previous Day',
                onPressed: () => _step(-1, 'previous_day'),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined),
                tooltip: l10n?.dayDetailsJumpToDate ?? 'Jump to Date',
                onPressed: () {
                  _analyticsService.logButtonClick(
                    buttonName: 'jump_to_date',
                    buttonLocation: 'day_details_appbar',
                  );
                  _showDatePicker(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: l10n?.dayDetailsNextDay ?? 'Next Day',
                onPressed: () => _step(1, 'next_day'),
              ),
              IconButton(
                icon: Icon(t.isClear ? Icons.ios_share : Icons.share_outlined),
                tooltip: l10n?.share ?? 'Share',
                onPressed: () => _shareDate(
                  _formatDetailedShareText(
                    context,
                    _completeDate,
                    showShanCalendar,
                  ),
                ),
              ),
            ],
            floatingActionButton: t.isClear
                ? null
                : FloatingActionButton(
                    heroTag: 'event',
                    tooltip: l10n?.dayDetailsAddEvent ?? 'Add Event',
                    onPressed: () {
                      _analyticsService.logButtonClick(
                        buttonName: 'add_event',
                        buttonLocation: 'day_details_fab',
                      );
                      _eventActionsPort.openCreateEvent(
                        context,
                        initialDate: _currentDate,
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 14),
                        child: Text(
                          '${_currentDate.year} · ${_relativeLabel(l10n)}',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: _isSameDay(_currentDate, DateTime.now())
                                ? t.accent
                                : t.secondaryLabel,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DayDetailsContent(
                        key: ValueKey<DateTime>(_currentDate),
                        date: _currentDate,
                        completeDate: _completeDate,
                        showShanCalendar: showShanCalendar,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final selectedWesternDate = await showAppMyanmarDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedWesternDate != null) {
      _analyticsService.logDateSelection(
        selectedDate: selectedWesternDate.toString(),
        calendarType: 'myanmar',
        dateFormat: 'from_date_picker',
      );
      _navigateToDay(selectedWesternDate);
    }
  }

  void _shareDate(String text) async {
    final l10n = AppLocalizations.of(context);
    try {
      HapticFeedback.lightImpact();
      await share(
        title: l10n?.dayDetailsShareDay ?? 'Share Day',
        subject:
            l10n?.dayDetailsShareSubject ?? 'Please check myanmar calendar',
        content: text,
      );

      await _analyticsService.logShare(
        contentType: 'date_details',
        platform: 'device_share',
        metadata: {
          'date': _currentDate.toString(),
          'year': _currentDate.year.toString(),
          'month': _currentDate.month.toString(),
          'day': _currentDate.day.toString(),
          'has_holidays': _completeDate.hasHolidays ? 'true' : 'false',
          'holiday_count':
              (_completeDate.allHolidays.length +
                      _completeDate.allAnniversaryDays.length)
                  .toString(),
          'moon_phase': _completeDate.moonPhase.toString(),
          'has_sabbath': _completeDate.sabbath.isNotEmpty ? 'true' : 'false',
          'has_yatyaza': _completeDate.yatyaza.isNotEmpty ? 'true' : 'false',
          'has_pyathada': _completeDate.pyathada.isNotEmpty ? 'true' : 'false',
        },
      );
    } catch (e, stack) {
      await _analyticsService.logException(
        exceptionName: 'ShareError',
        description: 'Failed to share: $e',
        stackTrace: stack.toString(),
      );

      if (!mounted) {
        return;
      }

      context.showToast(
        l10n?.dayDetailsShareFailed ?? 'Failed to share',
        kind: AppToastKind.error,
      );
    }
  }

  String _formatDetailedShareText(
    BuildContext context,
    CompleteDate completeDate, [
    bool showShanCalendar = true,
  ]) {
    final buffer = StringBuffer();
    final l10n = AppLocalizations.of(context);

    // The day on screen, not today.
    buffer.writeln('📅 ${context.calendarFormat.fullDate(_currentDate)}');
    buffer.writeln(
      '🇲🇲 ${_myanmarDateString(completeDate, showShanCalendar)}',
    );
    buffer.writeln('');

    if (completeDate.hasHolidays || completeDate.hasAnniversaryDays) {
      buffer.writeln('🎊 ${l10n?.holidays ?? "Holidays"}:');
      for (final holiday in completeDate.allHolidays) {
        buffer.writeln('• $holiday');
      }
      for (final anniversary in completeDate.allAnniversaryDays) {
        buffer.writeln('• $anniversary');
      }
      buffer.writeln('');
    }

    buffer.writeln(
      '☸️ ${l10n?.sasana_year ?? "Sasana Year"}: ${translateNumbers(completeDate.sasanaYear.toString())}',
    );
    buffer.writeln(
      '☀️ ${l10n?.buddhist_era ?? "Buddhist Era"}: ${translateNumbers((_currentDate.year + 543).toString())}',
    );
    buffer.writeln('');

    buffer.writeln(
      '🌙 ${l10n?.moon_phase ?? "Moon Phase"}: ${TranslationService.getMoonPhaseName(completeDate.moonPhase, MyanmarCalendar.currentLanguage)}',
    );
    buffer.writeln(
      '🗓️ ${l10n?.weekday ?? "Weekday"}: ${TranslationService.getWeekdayName(completeDate.weekday, MyanmarCalendar.currentLanguage)}',
    );
    buffer.writeln('');

    buffer.writeln(
      '✨ ${l10n?.astrological_information ?? "Astrological Info"}:',
    );
    // Marks that name themselves, then the values as phrases, all in the
    // calendar language.
    final language = MyanmarCalendar.currentLanguage;
    for (final mark in [
      completeDate.sabbath,
      completeDate.yatyaza,
      completeDate.pyathada,
      ...completeDate.astrologicalDays,
    ]) {
      if (mark.isNotEmpty) {
        buffer.writeln('• ${AstroPhrases.mark(mark, language)}');
      }
    }
    for (final (value, phrase) in [
      (completeDate.mahabote, AstroPhrases.mahabote),
      (completeDate.nakhat, AstroPhrases.nakhat),
      (completeDate.yearName, AstroPhrases.yearName),
      (completeDate.nagahle, AstroPhrases.nagahle),
    ]) {
      if (value.isNotEmpty) buffer.writeln('• ${phrase(value, language)}');
    }

    return buffer.toString().trim();
  }

  String _myanmarDateString(
    CompleteDate completeDate, [
    bool showShanCalendar = true,
  ]) {
    final myanmarDateTime = MyanmarDateTime.fromMyanmarDate(
      completeDate.myanmar,
    );
    if (showShanCalendar && MyanmarCalendar.currentLanguage == Language.shan) {
      return '${myanmarDateTime.shanDate.year} ${myanmarDateTime.formatMyanmar("&M &P &f &Yat")}';
    }
    return myanmarDateTime.formatMyanmar();
  }
}

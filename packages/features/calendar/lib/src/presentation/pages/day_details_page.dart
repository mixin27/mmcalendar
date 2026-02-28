import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_localizations/shared_localizations.dart';

import '../../di/calendar_injection.dart';
import '../widgets/day_details_content.dart';
import '../widgets/myanmar_date_picker_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) {
          return;
        }

        if (details.primaryVelocity! > 0) {
          final previousDay = _currentDate.subtract(const Duration(days: 1));
          _analyticsService.logWidgetInteraction(
            widgetName: 'day_details_page',
            actionType: 'swipe_previous',
            metadata: {
              'from_date': _currentDate.toString(),
              'to_date': previousDay.toString(),
            },
          );
          _navigateToDay(previousDay);
        } else if (details.primaryVelocity! < 0) {
          final nextDay = _currentDate.add(const Duration(days: 1));
          _analyticsService.logWidgetInteraction(
            widgetName: 'day_details_page',
            actionType: 'swipe_next',
            metadata: {
              'from_date': _currentDate.toString(),
              'to_date': nextDay.toString(),
            },
          );
          _navigateToDay(nextDay);
        }
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: 'event',
          onPressed: () async {
            _analyticsService.logButtonClick(
              buttonName: 'add_event',
              buttonLocation: 'day_details_fab',
            );
            await _eventActionsPort.openCreateEvent(
              context,
              initialDate: _currentDate,
            );
          },
          tooltip: 'Add Event',
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder<bool>(
          stream: _displayPreferencesPort.watchShowShanCalendar(),
          initialData: true,
          builder: (context, snapshot) {
            final showShanCalendar = snapshot.data ?? true;

            return CustomScrollView(
              slivers: [
                _buildAppBar(showShanCalendar),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Stack(
                          children: [
                            DayDetailsContent(
                              key: ValueKey<DateTime>(_currentDate),
                              date: _currentDate,
                              completeDate: _completeDate,
                              showShanCalendar: showShanCalendar,
                            ),
                            _buildTodayIndicator(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(bool showShanCalendar) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentDate.format('EEEE'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              _currentDate.format('MMMM d, yyyy'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            _analyticsService.logButtonClick(
              buttonName: 'previous_day',
              buttonLocation: 'day_details_appbar',
            );

            HapticFeedback.lightImpact();
            _navigateToDay(_currentDate.subtract(const Duration(days: 1)));
          },
          tooltip: 'Previous Day',
        ),
        IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () {
            _analyticsService.logButtonClick(
              buttonName: 'jump_to_date',
              buttonLocation: 'day_details_appbar',
            );
            _showDatePicker(context);
          },
          tooltip: 'Jump to Date',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            _analyticsService.logButtonClick(
              buttonName: 'next_day',
              buttonLocation: 'day_details_appbar',
            );

            HapticFeedback.lightImpact();
            _navigateToDay(_currentDate.add(const Duration(days: 1)));
          },
          tooltip: 'Next Day',
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () {
            final detailedShareText = _formatDetailedShareText(
              context,
              _completeDate,
              showShanCalendar,
            );
            _shareDate(detailedShareText);
          },
          tooltip: 'Share',
        ),
      ],
    );
  }

  Widget _buildTodayIndicator() {
    final isToday = _isSameDay(_currentDate, DateTime.now());
    if (!isToday) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.today,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              'Today',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final selectedDate = await showMyanmarDatePickerDialog(
      context: context,
      initialDate: _currentDate,
      language: MyanmarCalendar.currentLanguage,
    );

    if (selectedDate != null) {
      _analyticsService.logDateSelection(
        selectedDate: selectedDate.toString(),
        calendarType: 'myanmar',
        dateFormat: 'from_date_picker',
      );
      _navigateToDay(selectedDate);
    }
  }

  void _shareDate(String text) async {
    try {
      HapticFeedback.lightImpact();
      await share(
        title: 'Share Day',
        subject: 'Please check myanmar calendar',
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to share')));
    }
  }

  String _formatDetailedShareText(
    BuildContext context,
    CompleteDate completeDate, [
    bool showShanCalendar = true,
  ]) {
    final buffer = StringBuffer();
    final l10n = AppLocalizations.of(context);

    buffer.writeln('📅 ${_getTodayString()}');
    buffer.writeln('🇲🇲 ${_getTodayMyanmarString(showShanCalendar)}');
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
      '☀️ ${l10n?.buddhist_era ?? "Buddhist Era"}: ${translateNumbers((DateTime.now().year + 543).toString())}',
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
    if (completeDate.sabbath.isNotEmpty) {
      buffer.writeln(
        '• Sabbath: ${TranslationService.translateTo(completeDate.sabbath, MyanmarCalendar.currentLanguage)}',
      );
    }
    if (completeDate.yatyaza.isNotEmpty) {
      buffer.writeln(
        '• Yatyaza: ${TranslationService.translateTo(completeDate.yatyaza, MyanmarCalendar.currentLanguage)}',
      );
    }
    if (completeDate.pyathada.isNotEmpty) {
      buffer.writeln(
        '• Pyathada: ${TranslationService.translateTo(completeDate.pyathada, MyanmarCalendar.currentLanguage)}',
      );
    }
    if (completeDate.nagahle.isNotEmpty) {
      buffer.writeln(
        '• ${l10n?.nagahle ?? "Nagahle"}: ${TranslationService.translateTo(completeDate.nagahle, MyanmarCalendar.currentLanguage)}',
      );
    }
    if (completeDate.mahabote.isNotEmpty) {
      buffer.writeln(
        '• Mahabote: ${TranslationService.translateTo(completeDate.mahabote, MyanmarCalendar.currentLanguage)}',
      );
    }

    if (completeDate.astrologicalDays.isNotEmpty) {
      buffer.writeln('🌟 ${l10n?.special_days ?? "Special Days"}:');
      for (final day in completeDate.astrologicalDays) {
        buffer.writeln(
          '• ${TranslationService.translateTo(day, MyanmarCalendar.currentLanguage)}',
        );
      }
    }

    return buffer.toString().trim();
  }

  String _getTodayString() {
    final now = DateTime.now();
    return now.format('EEEE, MMMM d');
  }

  String _getTodayMyanmarString([bool showShanCalendar = true]) {
    final myanmarDateTime = MyanmarCalendar.today();

    if (showShanCalendar && MyanmarCalendar.currentLanguage == Language.shan) {
      return '${myanmarDateTime.shanDate.year} ${myanmarDateTime.formatMyanmar("&M &P &ff")}';
    }

    return myanmarDateTime.formatMyanmar();
  }
}

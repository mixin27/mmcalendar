import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/app/watch_colors.dart';
import 'package:myanmar_calendar_wear/features/day_details/models/day_details.dart';
import 'package:myanmar_calendar_wear/features/home/coming_up_page.dart';
import 'package:myanmar_calendar_wear/features/home/day_page.dart';
import 'package:myanmar_calendar_wear/features/home/watch_strings.dart';
import 'package:myanmar_calendar_wear/features/settings/views/language_settings_screen.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_moon/shared_moon.dart';

/// Today and the next days, then Coming up, as vertical pages: the Apple
/// Watch app's layout. Swipe or turn the crown to move between them.
class WatchHome extends StatefulWidget {
  const WatchHome({
    required this.language,
    required this.payload,
    required this.onLanguage,
    this.now,
    super.key,
  });

  /// How many day pages, starting today.
  static const dayPages = 7;

  final Language language;

  /// The slim payload the Tile draws; null until it's written.
  final Map<String, Object?>? payload;
  final VoidCallback onLanguage;

  /// The clock, for tests.
  final DateTime Function()? now;

  @override
  State<WatchHome> createState() => _WatchHomeState();
}

class _WatchHomeState extends State<WatchHome> {
  final _pages = PageController();
  late final AppLifecycleListener _lifecycle;
  Timer? _midnight;
  late DateTime _today = _todayNow();
  int _page = 0;

  DateTime _todayNow() {
    final now = (widget.now ?? DateTime.now)();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _checkDay);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = (widget.now ?? DateTime.now)();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now), () {
      _checkDay();
      _scheduleMidnight();
    });
  }

  /// A new day starts again on today's page.
  void _checkDay() {
    final today = _todayNow();
    if (today == _today) return;
    setState(() => _today = today);
    if (_pages.hasClients) _pages.jumpToPage(0);
  }

  @override
  void dispose() {
    _midnight?.cancel();
    _lifecycle.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final strings = WatchStrings(widget.payload, l10n);
    final upcoming = widget.payload == null
        ? null
        : ComingUpPage.parse(
            widget.payload,
          ).where((i) => !i.date.isBefore(_today)).toList();
    final sabbath = upcoming
        ?.where((i) => i.kind == 'sabbath' && i.date.isAfter(_today))
        .firstOrNull;
    const count = WatchHome.dayPages + 1;

    return Scaffold(
      backgroundColor: WatchColors.background,
      body: Stack(
        children: [
          PageView.builder(
            key: const ValueKey('watch-pages'),
            controller: _pages,
            scrollDirection: Axis.vertical,
            itemCount: count,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              if (index == WatchHome.dayPages) {
                return ComingUpPage(
                  items: upcoming,
                  today: _today,
                  strings: strings,
                  languageName: LanguageSettingsScreen.nameOf(widget.language),
                  onLanguage: widget.onLanguage,
                  onPullDown: () => _pages.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                );
              }
              final date = DateTime(
                _today.year,
                _today.month,
                _today.day + index,
              );
              return DayPage(
                day: DayDetails(date, widget.language),
                offset: index,
                strings: strings,
                nextSabbath: index == 0 && sabbath != null
                    ? '${sabbath.name} · '
                          '${strings.countdown(sabbath.date.difference(_today).inDays)}'
                    : null,
              );
            },
          ),
          Positioned(
            right: 7,
            top: 0,
            bottom: 0,
            child: Center(
              child: ExcludeSemantics(
                child: _PageDots(count: count, current: _page),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The vertical page indicator on the right edge.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < count; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 2),
          width: 4,
          height: i == current ? 10 : 4,
          decoration: BoxDecoration(
            color: i == current ? WatchColors.label : WatchColors.tertiary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
    ],
  );
}

/// The dimmed screen: today's date in grey on black, nothing to draw in
/// colour or animate, as Wear asks of ambient mode.
class AmbientDay extends StatelessWidget {
  const AmbientDay({required this.language, this.now, super.key});

  final Language language;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final day = DayDetails((now ?? DateTime.now)(), language);
    const dim = Color(0xFFB0B0B0);
    return ColoredBox(
      key: const ValueKey('watch-ambient'),
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MoonGlyph(
                  date: day.date,
                  size: 36,
                  texture: false,
                  colors: const MoonColors(
                    lit: dim,
                    shade: Colors.black,
                    rim: Color(0x66FFFFFF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  day.phaseLine,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: dim,
                  ),
                ),
                Text(
                  day.monthYear,
                  style: const TextStyle(fontSize: 14, color: dim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

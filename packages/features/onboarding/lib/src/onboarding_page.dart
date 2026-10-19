import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

/// The choices onboarding offers, read from and written back to settings
/// by the app.
class OnboardingSettings {
  const OnboardingSettings({
    required this.appLanguage,
    required this.calendarLanguage,
    required this.themeMode,
    required this.themePreset,
  });

  final String appLanguage;
  final Language calendarLanguage;
  final ThemeMode themeMode;
  final String themePreset;
}

/// What onboarding does to the app, so it needs no settings package.
class OnboardingActions {
  const OnboardingActions({
    required this.setAppLanguage,
    required this.setCalendarLanguage,
    required this.setThemeMode,
    required this.setThemePreset,
    required this.finish,
    required this.requestNotifications,
  });

  final ValueChanged<String> setAppLanguage;
  final ValueChanged<Language> setCalendarLanguage;
  final ValueChanged<ThemeMode> setThemeMode;
  final ValueChanged<String> setThemePreset;

  /// Saves the privacy choices and leaves onboarding.
  final Future<void> Function({
    required bool analytics,
    required bool crashReports,
  })
  finish;

  final Future<bool> Function() requestNotifications;
}

/// First run: four tour pages, then four setup steps and "All set". Skip
/// jumps from the tour to setup, since the setup choices matter more.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.settings,
    required this.actions,
  });

  final OnboardingSettings settings;
  final OnboardingActions actions;

  static const tourPages = 4;
  static const setupSteps = 4;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  var _page = 0;
  var _analytics = false;
  var _crashReports = false;
  var _finishing = false;

  static const _total =
      OnboardingPage.tourPages + OnboardingPage.setupSteps + 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() => _go(_page + 1);

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.actions.finish(
      analytics: _analytics,
      crashReports: _crashReports,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context)!;
    final inTour = _page < OnboardingPage.tourPages;
    final step = _page - OnboardingPage.tourPages;
    final inSetup = step >= 0 && step < OnboardingPage.setupSteps;
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        // A readable column on tablets and desktop.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        if (inSetup)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: _Steps(
                                count: OnboardingPage.setupSteps,
                                current: step,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        if (inTour)
                          TextButton(
                            key: const ValueKey('onboarding-skip'),
                            onPressed: () => _go(OnboardingPage.tourPages),
                            child: Text(
                              l10n.onboardingSkip,
                              style: TextStyle(color: t.accent, fontSize: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    key: const ValueKey('onboarding-pages'),
                    controller: _pages,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _TourPage(
                        art: _WelcomeArt(),
                        title: l10n.onboardingWelcomeTitle,
                        body: l10n.onboardingWelcomeBody,
                      ),
                      _TourPage(
                        art: const _WeekArt(),
                        title: l10n.onboardingCalendarsTitle,
                        body: l10n.onboardingCalendarsBody,
                      ),
                      _TourPage(
                        art: const _HolidayArt(),
                        title: l10n.onboardingHolidaysTitle,
                        body: l10n.onboardingHolidaysBody,
                      ),
                      _TourPage(
                        art: const _YoursArt(),
                        title: l10n.onboardingYoursTitle,
                        body: l10n.onboardingYoursBody,
                      ),
                      _LanguagesStep(
                        settings: widget.settings,
                        actions: widget.actions,
                      ),
                      _LookStep(
                        settings: widget.settings,
                        actions: widget.actions,
                      ),
                      _PrivacyStep(
                        analytics: _analytics,
                        crashReports: _crashReports,
                        onAnalytics: (v) => setState(() => _analytics = v),
                        onCrashReports: (v) =>
                            setState(() => _crashReports = v),
                      ),
                      _NotificationsStep(
                        onAllow: () async {
                          await widget.actions.requestNotifications();
                          _next();
                        },
                      ),
                      const _DoneStep(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      if (inTour) ...[
                        _Dots(count: OnboardingPage.tourPages, current: _page),
                        const SizedBox(height: 16),
                      ],
                      if (step == 3)
                        const SizedBox.shrink()
                      else
                        AppButton(
                          key: const ValueKey('onboarding-next'),
                          label: _page == _total - 1
                              ? l10n.onboardingStart
                              : _page == OnboardingPage.tourPages - 1
                              ? l10n.onboardingSetUp
                              : l10n.onboardingContinue,
                          onPressed: _page == _total - 1
                              ? (_finishing ? null : _finish)
                              : _next,
                        ),
                      if (step == 3)
                        AppButton(
                          key: const ValueKey('onboarding-not-now'),
                          label: l10n.onboardingNotNow,
                          kind: AppButtonKind.plain,
                          onPressed: _next,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current ? t.accent : t.fill,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= current ? t.accent : t.fill,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

TextStyle _titleStyle(BuildContext context) {
  final t = context.tokens;
  return TextStyle(
    color: t.label,
    fontSize: 26,
    fontWeight: t.isClear ? FontWeight.w800 : FontWeight.w500,
    height: 1.35,
    letterSpacing: t.isClear ? -.4 : 0,
  );
}

class _TourPage extends StatelessWidget {
  const _TourPage({required this.art, required this.title, required this.body});

  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(child: Center(child: art)),
          Text(title, textAlign: TextAlign.center, style: _titleStyle(context)),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.secondaryLabel,
              fontSize: 15.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// A setup step: progress label, title, then its controls.
class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.title,
    required this.children,
    this.icon,
    this.iconColor,
    this.body,
  });

  final int index;
  final String title;
  final String? body;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context)!;
    final centred = icon != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if (icon != null) ...[
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          l10n
              .onboardingStep(index + 1, OnboardingPage.setupSteps)
              .toUpperCase(),
          textAlign: centred ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: t.secondaryLabel,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: centred ? TextAlign.center : TextAlign.start,
          style: _titleStyle(context),
        ),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(
            body!,
            textAlign: centred ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: t.secondaryLabel,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 20),
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const SizedBox(height: 22),
          c,
        ],
      ],
    );
  }
}

class _LanguagesStep extends StatefulWidget {
  const _LanguagesStep({required this.settings, required this.actions});

  final OnboardingSettings settings;
  final OnboardingActions actions;

  @override
  State<_LanguagesStep> createState() => _LanguagesStepState();
}

class _LanguagesStepState extends State<_LanguagesStep> {
  late var _app = widget.settings.appLanguage;
  late var _calendar = widget.settings.calendarLanguage;

  static const _calendarLanguages = [
    (Language.myanmar, 'မြန်မာ'),
    (Language.english, 'English'),
    (Language.zawgyi, 'Zawgyi'),
    (Language.mon, 'Mon'),
    (Language.shan, 'Shan'),
    (Language.karen, 'Karen'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Step(
      index: 0,
      title: l10n.onboardingLanguagesTitle,
      children: [
        AppGroup(
          label: l10n.onboardingAppLanguage,
          children: [
            for (final (code, name) in [('my', 'မြန်မာ'), ('en', 'English')])
              AppRow(
                key: ValueKey('onboarding-app-language-$code'),
                title: name,
                selected: _app == code,
                onTap: () {
                  setState(() => _app = code);
                  widget.actions.setAppLanguage(code);
                },
              ),
          ],
        ),
        AppGroup(
          label: l10n.calendarLanguage,
          footer: l10n.onboardingCalendarLanguageFooter,
          children: [
            for (final (language, name) in _calendarLanguages)
              AppRow(
                key: ValueKey('onboarding-calendar-language-${language.code}'),
                title: name,
                selected: _calendar == language,
                onTap: () {
                  setState(() => _calendar = language);
                  widget.actions.setCalendarLanguage(language);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _LookStep extends StatefulWidget {
  const _LookStep({required this.settings, required this.actions});

  final OnboardingSettings settings;
  final OnboardingActions actions;

  @override
  State<_LookStep> createState() => _LookStepState();
}

class _LookStepState extends State<_LookStep> {
  late var _mode = widget.settings.themeMode;
  late var _preset = widget.settings.themePreset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    final modes = [
      (ThemeMode.system, l10n.onboardingThemeAutomatic),
      (ThemeMode.light, l10n.onboardingThemeLight),
      (ThemeMode.dark, l10n.onboardingThemeDark),
    ];
    return _Step(
      index: 1,
      title: l10n.onboardingLookTitle,
      children: [
        Row(
          children: [
            for (final (i, (mode, label)) in modes.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _ModeCard(
                  key: ValueKey('onboarding-theme-${mode.name}'),
                  mode: mode,
                  label: label,
                  selected: _mode == mode,
                  onTap: () {
                    setState(() => _mode = mode);
                    widget.actions.setThemeMode(mode);
                  },
                ),
              ),
            ],
          ],
        ),
        AppGroup(
          label: l10n.onboardingColour,
          footer: l10n.onboardingColourFooter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (final preset in ThemePresets.getAllPresets())
                    GestureDetector(
                      key: ValueKey('onboarding-preset-${preset.id}'),
                      onTap: () {
                        setState(() => _preset = preset.id);
                        widget.actions.setThemePreset(preset.id);
                      },
                      child: Semantics(
                        button: true,
                        selected: _preset == preset.id,
                        label: preset.name,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: preset.lightColors.primary,
                            shape: BoxShape.circle,
                            border: _preset == preset.id
                                ? Border.all(color: t.surface, width: 3)
                                : null,
                            boxShadow: _preset == preset.id
                                ? [BoxShadow(color: t.accent, spreadRadius: 2)]
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    super.key,
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget phone(Color bg, Color bar, Color line) => Container(
      width: 30,
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: t.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 14,
            decoration: BoxDecoration(
              color: bar,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
    final light = phone(
      const Color(0xFFF2F2F7),
      const Color(0xFF2F5BEA),
      const Color(0xFFC7C7CC),
    );
    final dark = phone(
      const Color(0xFF1C1C1E),
      const Color(0xFF5B83FF),
      const Color(0xFF48484A),
    );
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? t.accent : t.separator,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: switch (mode) {
                  ThemeMode.light => [light],
                  ThemeMode.dark => [dark],
                  ThemeMode.system => [light, const SizedBox(width: 4), dark],
                },
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: t.label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyStep extends StatelessWidget {
  const _PrivacyStep({
    required this.analytics,
    required this.crashReports,
    required this.onAnalytics,
    required this.onCrashReports,
  });

  final bool analytics;
  final bool crashReports;
  final ValueChanged<bool> onAnalytics;
  final ValueChanged<bool> onCrashReports;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Step(
      index: 2,
      icon: Icons.shield_outlined,
      iconColor: const Color(0xFF1F9D63),
      title: l10n.onboardingPrivacyTitle,
      body: l10n.onboardingPrivacyBody,
      children: [
        AppGroup(
          footer: l10n.onboardingPrivacyFooter,
          children: [
            AppRow.toggle(
              key: const ValueKey('onboarding-analytics'),
              icon: Icons.insights_outlined,
              iconColor: const Color(0xFF2F5BEA),
              title: l10n.onboardingUsageStats,
              subtitle: l10n.onboardingUsageStatsSubtitle,
              value: analytics,
              onChanged: onAnalytics,
            ),
            AppRow.toggle(
              key: const ValueKey('onboarding-crash-reports'),
              icon: Icons.bug_report_outlined,
              iconColor: const Color(0xFFF08A1C),
              title: l10n.onboardingCrashReports,
              subtitle: l10n.onboardingCrashReportsSubtitle,
              value: crashReports,
              onChanged: onCrashReports,
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationsStep extends StatelessWidget {
  const _NotificationsStep({required this.onAllow});

  final Future<void> Function() onAllow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    return _Step(
      index: 3,
      icon: Icons.notifications_outlined,
      iconColor: t.moon,
      title: l10n.onboardingNotificationsTitle,
      children: [
        AppGroup(
          children: [
            AppRow(
              icon: Icons.event_outlined,
              iconColor: const Color(0xFFE0457B),
              title: l10n.onboardingEventReminders,
              subtitle: l10n.onboardingEventRemindersSubtitle,
            ),
            AppRow(
              icon: Icons.star_rounded,
              iconColor: t.holiday,
              title: l10n.onboardingHolidayReminders,
              subtitle: l10n.onboardingHolidayRemindersSubtitle,
            ),
          ],
        ),
        AppButton(
          key: const ValueKey('onboarding-allow-notifications'),
          label: l10n.onboardingAllowNotifications,
          onPressed: onAllow,
        ),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    final format = context.calendarFormat;
    final now = DateTime.now();
    final myanmar = format.myanmar(
      MyanmarCalendar.fromWestern(now.year, now.month, now.day).myanmarDate,
      '&M &P &f',
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: t.success,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingDoneTitle,
          textAlign: TextAlign.center,
          style: _titleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingDoneToday('${format.fullDate(now)}, $myanmar'),
          textAlign: TextAlign.center,
          style: TextStyle(color: t.secondaryLabel, fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 28),
        AppGroup(
          children: [
            AppRow(
              icon: Icons.widgets_outlined,
              iconColor: const Color(0xFF16A3B0),
              title: l10n.onboardingWidgetTipTitle,
              subtitle: l10n.onboardingWidgetTipBody,
            ),
          ],
        ),
      ],
    );
  }
}

// MARK: Tour art

class _WelcomeArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      MoonGlyph(date: DateTime.now(), size: 168);
}

/// This week: dates, moons and lunar days, today highlighted.
class _WeekArt extends StatelessWidget {
  const _WeekArt();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final format = context.calendarFormat;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [for (var i = 0; i < 7; i++) today.add(Duration(days: i))];
    final dates = [
      for (final d in days) MyanmarCalendar.fromWestern(d.year, d.month, d.day),
    ];
    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (final (i, d) in days.indexed)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        format.weekday(d, short: true),
                        maxLines: 1,
                        style: TextStyle(
                          color: d.weekday == DateTime.sunday
                              ? t.holiday
                              : t.tertiaryLabel,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == 0 ? t.accent : null,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          format.number(d.day),
                          style: TextStyle(
                            color: i == 0 ? t.onAccent : t.label,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      MoonGlyph(date: d, size: 15),
                      const SizedBox(height: 4),
                      Text(
                        format.number(dates[i].fortnightDay),
                        maxLines: 1,
                        style: TextStyle(
                          color: dates[i].isSabbath
                              ? t.sabbath
                              : t.tertiaryLabel,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: dates[i].isSabbath
                              ? t.sabbath
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            format.myanmar(dates.first.myanmarDate, '&y &M &P &f'),
            style: TextStyle(color: t.secondaryLabel, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _HolidayArt extends StatelessWidget {
  const _HolidayArt();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget card(Color bg, Color fg, IconData icon, double width) => Container(
      width: width,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 8,
                  width: width * .45,
                  decoration: BoxDecoration(
                    color: t.label.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  width: width * .3,
                  decoration: BoxDecoration(
                    color: t.fill,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        card(t.holidaySoft, t.holiday, Icons.star_rounded, 260),
        const SizedBox(height: 10),
        card(t.accentSoft, t.accent, Icons.notifications_outlined, 240),
        const SizedBox(height: 10),
        card(t.holidaySoft, t.holiday, Icons.star_rounded, 260),
      ],
    );
  }
}

class _YoursArt extends StatelessWidget {
  const _YoursArt();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 10,
          children: [
            for (final preset in ThemePresets.getAllPresets())
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: preset.lightColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, icon) in [
              Icons.widgets_outlined,
              Icons.palette_outlined,
              Icons.edit_calendar_outlined,
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 12),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .10),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, size: 34, color: t.accent),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

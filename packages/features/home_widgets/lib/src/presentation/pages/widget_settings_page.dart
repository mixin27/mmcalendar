import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide WidgetState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../data/payload/widget_palettes.dart';
import '../../data/services/widget_update_service.dart';
import '../../domain/entities/widget_config.dart';
import '../bloc/widget_bloc.dart';
import '../bloc/widget_event.dart';
import '../bloc/widget_state.dart';

/// Settings › Widgets: the style new widgets start with, what they show,
/// what Countdown counts to, and how to add them.
class WidgetSettingsPage extends StatefulWidget {
  const WidgetSettingsPage({super.key});

  @override
  State<WidgetSettingsPage> createState() => _WidgetSettingsPageState();
}

class _WidgetSettingsPageState extends State<WidgetSettingsPage> {
  WidgetLoaded? _loaded;
  late Future<int> _installed = _countInstalled();
  final Future<bool> _canPin = _pinSupported();

  static Future<bool> _pinSupported() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<int> _countInstalled() async {
    try {
      return (await HomeWidget.getInstalledWidgets()).length;
    } catch (_) {
      return 0;
    }
  }

  void _update(BuildContext context, WidgetConfig config) =>
      context.read<WidgetBloc>().add(UpdateWidgetConfig(config));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<WidgetBloc, WidgetState>(
      listener: (context, state) {
        if (state is WidgetLoaded) _loaded = state;
        if (state is WidgetError) {
          context.showToast(state.message, kind: AppToastKind.error);
        }
      },
      builder: (context, state) {
        final loaded = state is WidgetLoaded ? state : _loaded;
        return AppPage(
          title: l10n.widgetSettings,
          previousTitle: l10n.settings,
          children: loaded == null
              ? const [
                  Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ]
              : _groups(context, loaded.config, l10n),
        );
      },
    );
  }

  List<Widget> _groups(
    BuildContext context,
    WidgetConfig config,
    AppLocalizations l10n,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palettes = WidgetPalettes.all(
      app: (
        light: WidgetPalette.fromTokens(context.tokens),
        dark: WidgetPalette.fromTokens(context.tokens),
      ),
    );
    WidgetPalette palette(WidgetStyleId style) => WidgetPalette.fromJson(
      (palettes[style.name]! as Map)[dark ? 'dark' : 'light']
          as Map<String, dynamic>,
    );
    final language = Language.fromCode(config.language);
    return [
      AppGroup(
        label: l10n.widgetsStyle,
        footer: l10n.widgetsStyleFooter,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, box) => Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (final style in WidgetStyleId.values)
                    SizedBox(
                      width: ((box.maxWidth - 20) / 3).clamp(96, 140),
                      child: _StyleChoice(
                        key: ValueKey('widget-style-${style.name}'),
                        title: _styleTitle(style, l10n),
                        palette: palette(style),
                        language: language,
                        selected: config.style == style,
                        onTap: () =>
                            _update(context, config.copyWith(style: style)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      AppGroup(
        label: l10n.widgetsShow,
        footer: l10n.widgetsLanguageNote(_languageName(language)),
        children: [
          AppRow.toggle(
            icon: Icons.celebration_outlined,
            iconColor: const Color(0xFFE5383B),
            title: l10n.holidays,
            value: config.showHolidays,
            onChanged: (v) =>
                _update(context, config.copyWith(showHolidays: v)),
          ),
          AppRow.toggle(
            icon: Icons.brightness_3_outlined,
            iconColor: const Color(0xFFF2A900),
            title: l10n.sabbath,
            value: config.showSabbath,
            onChanged: (v) => _update(context, config.copyWith(showSabbath: v)),
          ),
          AppRow.toggle(
            icon: Icons.auto_awesome_outlined,
            iconColor: const Color(0xFF8E6CEF),
            title: l10n.astrology,
            value: config.showAstrology,
            onChanged: (v) =>
                _update(context, config.copyWith(showAstrology: v)),
          ),
          AppRow.toggle(
            icon: Icons.event_outlined,
            iconColor: const Color(0xFF2F5BEA),
            title: l10n.events,
            value: config.showEvents,
            onChanged: (v) => _update(context, config.copyWith(showEvents: v)),
          ),
        ],
      ),
      AppGroup(
        label: l10n.widgetsCountdown,
        children: [
          for (final target in CountdownTarget.values)
            AppRow(
              key: ValueKey('widget-countdown-${target.name}'),
              title: switch (target) {
                CountdownTarget.fullMoon => l10n.widgetCountdownFullMoon,
                CountdownTarget.newMoon => l10n.widgetCountdownNewMoon,
                CountdownTarget.sabbath => l10n.widgetCountdownSabbath,
                CountdownTarget.thingyan => l10n.widgetCountdownThingyan,
              },
              selected: config.countdownTarget == target,
              onTap: () =>
                  _update(context, config.copyWith(countdownTarget: target)),
            ),
        ],
      ),
      AppGroup(
        label: l10n.widgetsOnScreen,
        children: [
          FutureBuilder<int>(
            future: _installed,
            builder: (context, count) => AppRow(
              icon: Icons.widgets_outlined,
              iconColor: const Color(0xFF16A3B0),
              title: l10n.widgetsInstalledTitle,
              value: count.hasData ? l10n.widgetsInstalled(count.data!) : null,
            ),
          ),
          AppRow(
            key: const ValueKey('widgets-refresh'),
            icon: Icons.refresh,
            iconColor: const Color(0xFF1F9D63),
            title: l10n.widgetsRefresh,
            tone: AppRowTone.accent,
            onTap: () {
              context.read<WidgetBloc>().add(const RefreshWidget());
              setState(() => _installed = _countInstalled());
              context.showToast(l10n.widgetsRefreshed);
            },
          ),
        ],
      ),
      FutureBuilder<bool>(
        future: _canPin,
        builder: (context, canPin) => canPin.data != true
            ? const SizedBox.shrink()
            : AppGroup(
                label: l10n.widgetsAddToHome,
                footer: l10n.widgetsAddToHomeFooter,
                children: [
                  for (final (receiver, title) in _kinds(l10n))
                    AppRow(
                      key: ValueKey('widget-pin-$receiver'),
                      icon: Icons.add_circle_outline,
                      iconColor: context.tokens.accent,
                      title: title,
                      onTap: () => HomeWidget.requestPinWidget(
                        qualifiedAndroidName:
                            WidgetUpdateService.androidReceiver(receiver),
                      ),
                    ),
                ],
              ),
      ),
      AppGroup(
        label: l10n.widgetsHowToAdd,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              defaultTargetPlatform == TargetPlatform.iOS
                  ? l10n.widgetsHowToAddIos
                  : l10n.widgetsHowToAddAndroid,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: context.tokens.label,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  /// The Android widgets, in the order of the widget picker.
  static List<(String, String)> _kinds(AppLocalizations l10n) => [
    ('TodayWidgetReceiver', l10n.widgetKindToday),
    ('MoonWidgetReceiver', l10n.widgetKindMoon),
    ('MonthWidgetReceiver', l10n.widgetKindMonth),
    ('WeekWidgetReceiver', l10n.widgetKindWeek),
    ('ComingUpWidgetReceiver', l10n.widgetKindComingUp),
    ('AgendaWidgetReceiver', l10n.widgetKindAgenda),
    ('CountdownWidgetReceiver', l10n.widgetKindCountdown),
    ('AstrologyWidgetReceiver', l10n.widgetKindAstrology),
    ('YearWidgetReceiver', l10n.widgetKindYear),
  ];

  static String _styleTitle(WidgetStyleId style, AppLocalizations l10n) =>
      switch (style) {
        WidgetStyleId.app => l10n.widgetStyleApp,
        WidgetStyleId.plain => l10n.widgetStylePlain,
        WidgetStyleId.pagoda => l10n.gridThemePagodaTitle,
        WidgetStyleId.jade => l10n.gridThemeJadeTitle,
        WidgetStyleId.deepField => l10n.gridThemeDeepFieldTitle,
      };

  static String _languageName(Language language) => switch (language) {
    Language.myanmar => 'မြန်မာ',
    Language.english => 'English',
    Language.zawgyi => 'Zawgyi',
    Language.mon => 'Mon',
    Language.shan => 'Shan',
    Language.karen => 'Karen',
  };
}

/// A style as a tiny Today widget: weekday, date, moon and lunar day in the
/// style's colours.
class _StyleChoice extends StatelessWidget {
  const _StyleChoice({
    super.key,
    required this.title,
    required this.palette,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final WidgetPalette palette;
  final Language language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final today = DateTime.now();
    final format = CalendarFormat(language);
    final lunar = MyanmarCalendar.fromWestern(
      today.year,
      today.month,
      today.day,
    ).formatMyanmar('&P &f', language);
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? t.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: t.separator, width: .5),
                  ),
                  child: FittedBox(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            format.weekday(today, short: true),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: palette.holiday,
                            ),
                          ),
                          Text(
                            format.number(today.day),
                            style: TextStyle(
                              fontSize: 38,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              MoonGlyph(
                                date: today,
                                size: 14,
                                colors: MoonColors(
                                  lit: palette.moon,
                                  shade: palette.shade,
                                  rim: palette.line,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  lunar,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: palette.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? t.accent : t.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:calendar/calendar.dart' show CalendarGrid;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../domain/entities/app_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../widgets/settings_widgets.dart';

/// Accents offered as swatches: the four presets first, then a spread of
/// hues that keep white text readable.
const _accents = <Color>[
  Color(0xFF2F5BEA),
  Color(0xFF8B1A1A),
  Color(0xFF0277BD),
  Color(0xFF2E7D32),
  Color(0xFFB3261E),
  Color(0xFFC2410C),
  Color(0xFFB45309),
  Color(0xFF8A6210),
  Color(0xFF4D7C0F),
  Color(0xFF0E6B5C),
  Color(0xFF0E7490),
  Color(0xFF4338CA),
  Color(0xFF6D28D9),
  Color(0xFFA21CAF),
  Color(0xFFBE185D),
  Color(0xFF57534E),
];

extension CustomColorSlotLabel on CustomColorSlot {
  String label(AppLocalizations l10n) => switch (this) {
    CustomColorSlot.primary => l10n.customColorPrimary,
    CustomColorSlot.onPrimary => l10n.customColorOnPrimary,
    CustomColorSlot.secondary => l10n.customColorSecondary,
    CustomColorSlot.onSecondary => l10n.customColorOnSecondary,
    CustomColorSlot.tertiary => l10n.customColorTertiary,
    CustomColorSlot.onTertiary => l10n.customColorOnTertiary,
    CustomColorSlot.error => l10n.customColorError,
    CustomColorSlot.onError => l10n.customColorOnError,
    CustomColorSlot.surface => l10n.customColorSurface,
    CustomColorSlot.onSurface => l10n.customColorOnSurface,
  };
}

/// Settings › Appearance › Custom colours: one accent that makes the light
/// and dark schemes, a live preview of both, and every slot by hand under
/// Advanced. Nothing changes until Apply.
class SettingsCustomColorsPage extends StatefulWidget {
  const SettingsCustomColorsPage({super.key});

  @override
  State<SettingsCustomColorsPage> createState() =>
      _SettingsCustomColorsPageState();
}

class _SettingsCustomColorsPageState extends State<SettingsCustomColorsPage> {
  CustomColors? _draft;
  var _advanced = false;
  var _editing = Brightness.light;

  CustomColors _start(AppSettingsEntity settings) {
    final custom = settings.customColors;
    if (settings.themePreset == 'custom' && custom != null) return custom;
    final preset = ThemePresets.getPreset(settings.themePreset);
    return CustomColors(
      seed: preset.lightColors.primary,
      basePreset: preset.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsSubPage(
      title: l10n.customColorsTitle,
      previousTitle: l10n.appearance,
      actions: [
        TextButton(
          key: const ValueKey('custom-colors-apply'),
          onPressed: () => _apply(context),
          child: Text(
            l10n.apply,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
      builder: (context, settings) {
        final draft = _draft ??= _start(settings);
        return [
          _Previews(colors: draft, label: l10n.customColorsPreview),
          AppGroup(
            label: l10n.customColorsAccent,
            footer: l10n.customColorsAccentFooter,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                // Two even rows of eight on a phone.
                child: GridView.count(
                  crossAxisCount: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 4,
                  children: [
                    for (final (i, color) in _accents.indexed)
                      _AccentSwatch(
                        key: ValueKey('custom-accent-$i'),
                        color: color,
                        selected: draft.seed == color,
                        onTap: () =>
                            setState(() => _draft = draft.withSeed(color)),
                      ),
                  ],
                ),
              ),
              AppRow(
                key: const ValueKey('custom-colors-more'),
                leading: _Dot(color: draft.seed, size: 22),
                title: l10n.customColorsMore,
                chevron: true,
                onTap: () => _pick(context, draft.seed, draft.withSeed),
              ),
            ],
          ),
          AppGroup(
            footer: _advanced ? l10n.customColorsAdvancedFooter : null,
            children: [
              AppRow(
                key: const ValueKey('custom-colors-advanced'),
                title: l10n.customColorsAdvanced,
                trailing: AnimatedRotation(
                  turns: _advanced ? .25 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: context.tokens.tertiaryLabel,
                  ),
                ),
                onTap: () => setState(() => _advanced = !_advanced),
              ),
              if (_advanced) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  child: AppSegmented<Brightness>(
                    segments: {
                      Brightness.light: l10n.light,
                      Brightness.dark: l10n.dark,
                    },
                    value: _editing,
                    onChanged: (b) => setState(() => _editing = b),
                  ),
                ),
                for (final slot in CustomColorSlot.values)
                  AppRow(
                    key: ValueKey('custom-slot-${slot.name}'),
                    title: slot.label(l10n),
                    trailing: _Dot(
                      color: slot.of(draft.scheme(_editing)),
                      size: 22,
                    ),
                    chevron: true,
                    onTap: () => _pick(
                      context,
                      slot.of(draft.scheme(_editing)),
                      (c) => draft.withSlot(_editing, slot, c),
                    ),
                  ),
              ],
            ],
          ),
          if (settings.themePreset == 'custom')
            AppGroup(
              children: [
                AppRow(
                  key: const ValueKey('custom-colors-reset'),
                  title: l10n.customColorsReset,
                  tone: AppRowTone.destructive,
                  onTap: () => _reset(context, draft),
                ),
              ],
            ),
        ];
      },
    );
  }

  Future<void> _pick(
    BuildContext context,
    Color initial,
    CustomColors Function(Color) next,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final color = await showAppColorPicker(
      context: context,
      title: l10n.customColorsPickTitle,
      initial: initial,
      cancelLabel: l10n.cancel,
      doneLabel: l10n.done,
    );
    if (color != null && mounted) setState(() => _draft = next(color));
  }

  void _apply(BuildContext context) {
    final draft = _draft;
    if (draft == null) return;
    context.read<SettingsBloc>().add(UpdateCustomColors(draft));
    Navigator.of(context).maybePop();
  }

  Future<void> _reset(BuildContext context, CustomColors draft) async {
    final l10n = AppLocalizations.of(context)!;
    final preset = ThemePresets.getPreset(draft.basePreset);
    final yes = await showAppConfirm(
      context: context,
      title: l10n.customColorsReset,
      message: l10n.customColorsResetMessage(preset.name),
      confirmLabel: l10n.customColorsReset,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!yes || !context.mounted) return;
    context.read<SettingsBloc>().add(ChangeThemePreset(preset.id));
    Navigator.of(context).maybePop();
  }
}

/// This month in the draft colours, light and dark side by side, each with
/// a filled button and a switch.
class _Previews extends StatelessWidget {
  const _Previews({required this.colors, required this.label});

  final CustomColors colors;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = context.tokens.isClear ? AppStyle.clear : AppStyle.material;
    final month = DateTime.now();
    final dates = AppDateUtils.getCalendarGridDates(
      month,
      firstDayOfWeek: 1,
    ).map(MyanmarCalendar.getCompleteDate).toList(growable: false);
    Widget preview(Brightness b) => Expanded(
      child: Theme(
        data: AppTheme.build(style: style, colorScheme: colors.scheme(b)),
        child: Builder(builder: (context) => _Preview(month, dates)),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGroupLabel(label),
        Row(
          children: [
            preview(Brightness.light),
            const SizedBox(width: 12),
            preview(Brightness.dark),
          ],
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview(this.month, this.dates);

  final DateTime month;
  final List<CompleteDate> dates;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final rows = CalendarGrid.visibleRows(dates, month).length;
    final today = DateUtils.dateOnly(DateTime.now());
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          decoration: BoxDecoration(
            color: t.background,
            borderRadius: BorderRadius.circular(t.groupRadius),
            border: Border.all(color: t.separator, width: .5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  context.calendarFormat.monthYear(month),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.label,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.fitWidth,
                child: SizedBox(
                  width: 360,
                  height: rows * 60,
                  child: MediaQuery.withNoTextScaling(
                    child: CalendarGrid(
                      gridDates: dates,
                      currentMonth: month,
                      today: today,
                      selectedDate: today.add(const Duration(days: 2)),
                      gridStyle: CalendarGridStyle.clean,
                      onDateTap: (_) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 30,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.today ?? 'Today',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: .7,
                    child: AppSwitch(value: true, onChanged: (_) {}),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: selected
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: context.tokens.separator),
    ),
  );
}

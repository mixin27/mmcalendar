import 'package:flutter/material.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' show showAppColorPicker;

import '../../models/calendar_studio_project_theme.dart';
import '../../models/calendar_studio_types.dart';
import '../../templates/calendar_studio_bindings.dart';
import '../../theme/calendar_studio_theme.dart';
import '../calendar_studio_year_field.dart';
import 'inspector/studio_inspector_controls.dart';
import '../calendar_studio_strings.dart';

/// A page size Studio lays out well.
class StudioPageSize {
  const StudioPageSize(
    this.id,
    this.label,
    this.subtitle,
    this.width,
    this.height,
  );
  final String id;
  final String label;
  final String subtitle;
  final double width;
  final double height;

  static const all = [
    StudioPageSize(
      'a4',
      StudioStrings.a4Portrait,
      StudioStrings.a4PortraitHint,
      210,
      297,
    ),
    StudioPageSize(
      'a4-landscape',
      StudioStrings.a4Landscape,
      StudioStrings.a4LandscapeHint,
      297,
      210,
    ),
    StudioPageSize(
      'a3',
      StudioStrings.a3Portrait,
      StudioStrings.a3PortraitHint,
      297,
      420,
    ),
    StudioPageSize('square', StudioStrings.square, 'Social posts', 600, 600),
    StudioPageSize('story', StudioStrings.story916, 'Phone screens', 360, 640),
  ];

  static StudioPageSize? of(StudioCanvas canvas) {
    for (final size in all) {
      if (size.width == canvas.width && size.height == canvas.height) {
        return size;
      }
    }
    return null;
  }
}

/// Project settings being edited; nothing changes until they're applied.
class StudioSettingsDraft {
  const StudioSettingsDraft({
    required this.source,
    required this.theme,
    required this.width,
    required this.height,
    required this.bleed,
    required this.safeInset,
    required this.output,
    this.resizeAll = true,
  });
  final CalendarStudioSource source;
  final CalendarStudioProjectTheme theme;
  final double width;
  final double height;
  final bool resizeAll;
  final bool bleed;
  final double safeInset;
  final CalendarStudioExportPreset output;

  StudioSettingsDraft copyWith({
    CalendarStudioSource? source,
    CalendarStudioProjectTheme? theme,
    double? width,
    double? height,
    bool? resizeAll,
    bool? bleed,
    double? safeInset,
    CalendarStudioExportPreset? output,
  }) => StudioSettingsDraft(
    source: source ?? this.source,
    theme: theme ?? this.theme,
    width: width ?? this.width,
    height: height ?? this.height,
    resizeAll: resizeAll ?? this.resizeAll,
    bleed: bleed ?? this.bleed,
    safeInset: safeInset ?? this.safeInset,
    output: output ?? this.output,
  );
}

/// Every calendar language a project can use, as chips.
class StudioLanguageChips extends StatelessWidget {
  const StudioLanguageChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final CalendarStudioLanguage selected;
  final ValueChanged<CalendarStudioLanguage> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final language in CalendarStudioLanguage.values)
        ChoiceChip(
          key: ValueKey('calendar-studio-language-${language.name}'),
          // One height for every chip: Myanmar script would otherwise make
          // its chips taller than the Latin ones.
          label: SizedBox(
            height: 22,
            child: Center(
              widthFactor: 1,
              child: Text(switch (language) {
                CalendarStudioLanguage.myanmar => 'မြန်မာ',
                CalendarStudioLanguage.both => 'မြန်မာ + English',
                _ => language.label,
              }, style: const TextStyle(height: 1.25)),
            ),
          ),
          selected: selected == language,
          onSelected: (_) => onSelected(language),
        ),
    ],
  );
}

typedef StudioSettingsChanged = ValueChanged<StudioSettingsDraft>;

/// Period, year, start month, week start, language and what days show.
class StudioCalendarSettings extends StatelessWidget {
  const StudioCalendarSettings({
    required this.draft,
    required this.onChanged,
    super.key,
  });
  final StudioSettingsDraft draft;
  final StudioSettingsChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final source = draft.source;
    void set(CalendarStudioSource value) =>
        onChanged(draft.copyWith(source: value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: StudioStrings.calendar,
          children: [
            StudioSegmented<CalendarStudioPeriod>(
              segments: const [
                (CalendarStudioPeriod.month, StudioStrings.oneMonth, null),
                (CalendarStudioPeriod.year, StudioStrings.twelveMonths, null),
              ],
              value: source.period,
              onChanged: (v) => set(source.copyWith(period: v)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CalendarStudioYearField(
                    year: source.year,
                    onChanged: (v) => set(source.copyWith(year: v)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CalendarStudioMonthField(
                    key: ValueKey('settings-month-${source.month}'),
                    label: source.period == CalendarStudioPeriod.year
                        ? StudioStrings.startsFrom
                        : StudioStrings.month,
                    month: source.month,
                    names: StudioStrings.months,
                    onChanged: (v) => set(source.copyWith(month: v)),
                  ),
                ),
              ],
            ),
            StudioFieldRow(
              label: StudioStrings.weekStarts,
              child: StudioSegmented<bool>(
                segments: const [
                  (false, StudioStrings.sun, null),
                  (true, StudioStrings.mon, null),
                ],
                value: source.weekStartsMonday,
                onChanged: (v) => set(source.copyWith(weekStartsMonday: v)),
              ),
            ),
          ],
        ),
        StudioSection(
          title: StudioStrings.calendarLanguage,
          children: [
            StudioLanguageChips(
              selected: source.language,
              onSelected: (v) => set(source.copyWith(language: v)),
            ),
          ],
        ),
        StudioSection(
          title: StudioStrings.daysShow,
          children: [
            StudioSwitch(
              label: StudioStrings.myanmarDates,
              value: source.showMyanmarDate,
              onChanged: (v) => set(source.copyWith(showMyanmarDate: v)),
            ),
            StudioSwitch(
              label: StudioStrings.moonPhases,
              value: source.showMoonPhases,
              onChanged: (v) => set(source.copyWith(showMoonPhases: v)),
            ),
            StudioSwitch(
              label: StudioStrings.publicHolidays,
              value: source.showHolidays,
              onChanged: (v) => set(source.copyWith(showHolidays: v)),
            ),
            StudioSwitch(
              label: StudioStrings.astrologyDays,
              value: source.showAstrology,
              onChanged: (v) => set(source.copyWith(showAstrology: v)),
            ),
            StudioSwitch(
              label: StudioStrings.myEvents,
              value: source.showEvents,
              onChanged: (v) => set(source.copyWith(showEvents: v)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Palettes, a customise list of roles, and the font pair.
class StudioThemeSettings extends StatelessWidget {
  const StudioThemeSettings({
    required this.draft,
    required this.onChanged,
    required this.original,
    super.key,
  });
  final StudioSettingsDraft draft;
  final StudioSettingsChanged onChanged;

  /// The project's theme before these settings, listed first.
  final CalendarStudioProjectTheme original;

  CalendarStudioProjectTheme _custom(CalendarStudioProjectTheme theme) =>
      theme.id == 'custom'
      ? theme
      : theme.copyWith(id: 'custom', name: '${theme.name} (custom)');

  @override
  Widget build(BuildContext context) {
    final current = draft.theme;
    final themes = [
      original,
      for (final theme in CalendarStudioProjectThemes.library)
        if (theme.id != original.id) theme,
    ];
    void pick(CalendarStudioProjectTheme theme) =>
        onChanged(draft.copyWith(theme: theme));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: StudioStrings.theme,
          children: [
            SizedBox(
              height: 86,
              child: ListView.separated(
                key: const ValueKey('studio-theme-row'),
                scrollDirection: Axis.horizontal,
                itemCount: themes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) => _ThemeChip(
                  key: ValueKey('studio-theme-${themes[index].id}'),
                  theme: themes[index],
                  selected: themes[index].id == current.id,
                  onTap: () => pick(themes[index]),
                ),
              ),
            ),
            if (current.id == 'custom')
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(StudioStrings.customTheme(current.name)),
              ),
            ExpansionTile(
              key: const ValueKey('studio-theme-customize'),
              tilePadding: EdgeInsets.zero,
              title: const Text(StudioStrings.customiseColours),
              children: [
                for (final role in CalendarStudioProjectTheme.roles)
                  ListTile(
                    key: ValueKey('studio-theme-role-$role'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      CalendarStudioProjectTheme.roleLabels[role] ?? role,
                    ),
                    trailing: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(current.color(role)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CalendarStudioTokens.of(context).line,
                        ),
                      ),
                    ),
                    onTap: () async {
                      final color = await showAppColorPicker(
                        context: context,
                        title:
                            CalendarStudioProjectTheme.roleLabels[role] ?? role,
                        initial: Color(current.color(role)),
                        doneLabel: StudioStrings.done,
                      );
                      if (color != null) {
                        pick(current.withColor(role, color.toARGB32()));
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
        StudioSection(
          title: StudioStrings.fonts,
          children: [
            StudioFontField(
              label: StudioStrings.headings,
              value: current.displayFont ?? 'Fraunces',
              onChanged: (v) => pick(_custom(current).copyWith(displayFont: v)),
            ),
            StudioFontField(
              label: StudioStrings.body,
              value: current.bodyFont ?? 'Noto Sans Myanmar',
              onChanged: (v) => pick(_custom(current).copyWith(bodyFont: v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.theme,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final CalendarStudioProjectTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(theme.color('paper')),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? tokens.primary : tokens.line,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final role in const [
                  'primary',
                  'accent',
                  'ink',
                  'holiday',
                ])
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Color(theme.color(role)),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              theme.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(theme.color('ink')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page size, bleed and safe margin.
class StudioFormatSettings extends StatelessWidget {
  const StudioFormatSettings({
    required this.draft,
    required this.onChanged,
    this.pageCount = 1,
    super.key,
  });
  final StudioSettingsDraft draft;
  final StudioSettingsChanged onChanged;

  /// More than one shows "Resize every page".
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final custom = !StudioPageSize.all.any(
      (s) => s.width == draft.width && s.height == draft.height,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: StudioStrings.pageSize,
          children: [
            RadioGroup<String>(
              groupValue: custom
                  ? 'custom'
                  : StudioPageSize.all
                        .firstWhere(
                          (s) =>
                              s.width == draft.width &&
                              s.height == draft.height,
                        )
                        .id,
              onChanged: (id) {
                final size = StudioPageSize.all.where((s) => s.id == id);
                if (size.isEmpty) return;
                onChanged(
                  draft.copyWith(
                    width: size.first.width,
                    height: size.first.height,
                  ),
                );
              },
              child: Column(
                children: [
                  for (final size in StudioPageSize.all)
                    RadioListTile<String>(
                      key: ValueKey('studio-page-size-${size.id}'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: size.id,
                      title: Text(size.label),
                      subtitle: Text(size.subtitle),
                    ),
                  if (custom)
                    RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: 'custom',
                      title: const Text(StudioStrings.templateOwnSize),
                      subtitle: Text(
                        '${draft.width.round()} × ${draft.height.round()}',
                      ),
                    ),
                ],
              ),
            ),
            if (pageCount > 1)
              StudioSwitch(
                label: StudioStrings.resizeEveryPage,
                subtitle: StudioStrings.resizeEveryPageHint,
                value: draft.resizeAll,
                onChanged: (v) => onChanged(draft.copyWith(resizeAll: v)),
              ),
            Text(
              StudioStrings.pageSizeNote,
              style: TextStyle(
                fontSize: 12,
                color: CalendarStudioTokens.of(context).ink3,
              ),
            ),
          ],
        ),
        StudioSection(
          title: StudioStrings.printHeading,
          children: [
            StudioSwitch(
              label: StudioStrings.bleed,
              subtitle: StudioStrings.bleedHint,
              value: draft.bleed,
              onChanged: (v) => onChanged(draft.copyWith(bleed: v)),
            ),
            StudioStepper(
              label: StudioStrings.safeMargin,
              unit: '%',
              value: draft.safeInset * 100,
              max: 12,
              onChanged: (v) => onChanged(draft.copyWith(safeInset: v / 100)),
            ),
          ],
        ),
      ],
    );
  }
}

/// The export the Export button starts with.
class StudioOutputSettings extends StatelessWidget {
  const StudioOutputSettings({
    required this.draft,
    required this.onChanged,
    super.key,
  });
  final StudioSettingsDraft draft;
  final StudioSettingsChanged onChanged;

  static const presets = [
    CalendarStudioExportPreset.pagePdf,
    CalendarStudioExportPreset.pagePng,
    CalendarStudioExportPreset.a4Pdf,
    CalendarStudioExportPreset.a3Pdf,
    CalendarStudioExportPreset.highQualityPng,
    CalendarStudioExportPreset.screenPng,
    CalendarStudioExportPreset.squarePng,
    CalendarStudioExportPreset.storyPng,
  ];

  @override
  Widget build(BuildContext context) => StudioSection(
    title: StudioStrings.output,
    children: [
      RadioGroup<String>(
        groupValue: draft.output.id,
        onChanged: (id) => onChanged(
          draft.copyWith(output: presets.firstWhere((p) => p.id == id)),
        ),
        child: Column(
          children: [
            for (final preset in presets)
              RadioListTile<String>(
                key: ValueKey('studio-output-${preset.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: preset.id,
                title: Text(preset.label),
                subtitle: Text(
                  preset.matchesPage
                      ? StudioStrings.outputDetailPageSize(
                          preset.format.label,
                          preset.dpi,
                        )
                      : StudioStrings.outputDetail(
                          preset.format.label,
                          preset.dpi,
                          preset.width,
                          preset.height,
                        ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

/// Why there's no time zone choice.
class StudioTimeZoneNote extends StatelessWidget {
  const StudioTimeZoneNote({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) => StudioSection(
    title: StudioStrings.timeZone,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.schedule_outlined),
        title: Text(label),
        subtitle: const Text(StudioStrings.timeZoneNote),
      ),
    ],
  );
}

/// One screen for every project setting. Pops with the draft on Apply.
class CalendarStudioProjectSettingsPage extends StatefulWidget {
  const CalendarStudioProjectSettingsPage({
    required this.initial,
    required this.originalTheme,
    required this.projectName,
    required this.pageCount,
    required this.onSaveFile,
    required this.onShareFile,
    this.onSaveTemplate,
    super.key,
  });
  final StudioSettingsDraft initial;
  final CalendarStudioProjectTheme originalTheme;
  final String projectName;
  final int pageCount;
  final VoidCallback onSaveFile;
  final VoidCallback onShareFile;

  /// Leaves settings and opens Save as template; null without a store.
  final VoidCallback? onSaveTemplate;

  @override
  State<CalendarStudioProjectSettingsPage> createState() =>
      _CalendarStudioProjectSettingsPageState();
}

class _CalendarStudioProjectSettingsPageState
    extends State<CalendarStudioProjectSettingsPage> {
  late var _draft = widget.initial;

  void _set(StudioSettingsDraft draft) => setState(() => _draft = draft);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: StudioStrings.close,
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(StudioStrings.projectSettings),
          Text(
            widget.projectName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilledButton(
            key: const ValueKey('studio-settings-apply'),
            onPressed: () => Navigator.pop(context, _draft),
            child: const Text(StudioStrings.apply),
          ),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            StudioCalendarSettings(draft: _draft, onChanged: _set),
            StudioThemeSettings(
              draft: _draft,
              onChanged: _set,
              original: widget.originalTheme,
            ),
            StudioFormatSettings(
              draft: _draft,
              onChanged: _set,
              pageCount: widget.pageCount,
            ),
            StudioOutputSettings(draft: _draft, onChanged: _set),
            StudioTimeZoneNote(label: _draft.source.timeZoneLabel),
            StudioSection(
              title: StudioStrings.projectFile,
              children: [
                const Text(StudioStrings.projectFileNote),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onSaveFile,
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text(StudioStrings.saveProjectFile),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.onShareFile,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text(StudioStrings.share),
                    ),
                    if (widget.onSaveTemplate case final save?)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          save();
                        },
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text(StudioStrings.saveAsTemplate),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// New-project setup: the same settings in three short steps.
class CalendarStudioSetupSheet extends StatefulWidget {
  const CalendarStudioSetupSheet({
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.initial,
    required this.onCreate,
    super.key,
  });
  final String title;
  final String subtitle;
  final Widget preview;
  final StudioSettingsDraft initial;
  final ValueChanged<StudioSettingsDraft> onCreate;

  @override
  State<CalendarStudioSetupSheet> createState() =>
      _CalendarStudioSetupSheetState();
}

class _CalendarStudioSetupSheetState extends State<CalendarStudioSetupSheet> {
  late var _draft = widget.initial;
  var _step = 0;

  static const _steps = [
    StudioStrings.calendar,
    StudioStrings.theme,
    StudioStrings.format,
  ];

  void _set(StudioSettingsDraft draft) => setState(() => _draft = draft);

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.preview,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: StudioStrings.close,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              key: const ValueKey('studio-setup-steps'),
              showSelectedIcon: false,
              segments: [
                for (var i = 0; i < _steps.length; i++)
                  ButtonSegment(
                    value: i,
                    label: Text(StudioStrings.step(i + 1, _steps[i])),
                  ),
              ],
              selected: {_step},
              onSelectionChanged: (value) =>
                  setState(() => _step = value.first),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              switch (_step) {
                0 => StudioCalendarSettings(draft: _draft, onChanged: _set),
                1 => StudioThemeSettings(
                  draft: _draft,
                  onChanged: _set,
                  original: widget.initial.theme,
                ),
                _ => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudioFormatSettings(draft: _draft, onChanged: _set),
                    StudioOutputSettings(draft: _draft, onChanged: _set),
                  ],
                ),
              },
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surface,
            border: Border(top: BorderSide(color: tokens.line)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: [
                if (_step > 0) ...[
                  TextButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text(StudioStrings.back),
                  ),
                  const SizedBox(width: 4),
                ],
                if (_step < _steps.length - 1) ...[
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('studio-setup-next'),
                      onPressed: () => setState(() => _step++),
                      child: const Text(StudioStrings.next),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    key: const ValueKey('studio-setup-create'),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onCreate(_draft);
                    },
                    child: const Text(StudioStrings.createProject),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

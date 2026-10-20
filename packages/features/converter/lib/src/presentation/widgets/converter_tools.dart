import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../data/services/shan_year_preference.dart';
import '../../di/converter_injection.dart';
import '../../domain/entities/conversion_result.dart';
import '../../domain/entities/date_arithmetic_result.dart';
import '../../domain/entities/date_calculation_result.dart';
import '../../domain/entities/moon_phase_result.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';

// The four converter tools. They share one ConverterBloc, so each listens
// only to its own states and keeps its last result.

Language get _language => MyanmarCalendar.currentLanguage;
String _t(String key) => TranslationService.translateTo(key, _language);

/// A Myanmar date, with the Shan year when Settings › Prefer Shan Year.
String _myanmar(MyanmarDate date) => formatMyanmarDate(
  date,
  language: _language,
  preferShanYear:
      !getIt.isRegistered<ShanYearPreference>() ||
      getIt<ShanYearPreference>().value,
);

DateTime _dateOf(CompleteDate d) =>
    DateTime(d.westernYear, d.westernMonth, d.westernDay);

/// Dates are calendar data, so they follow the calendar language.
String _fullDate(BuildContext context, DateTime date) =>
    context.calendarFormat.fullDate(date);

/// A row that shows a date and opens the Myanmar date picker.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => AppRow(
    title: label,
    value: context.calendarFormat.shortDate(date),
    chevron: true,
    onTap: () async {
      final picked = await showAppMyanmarDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      if (picked != null) onChanged(picked);
    },
  );
}

/// A label on the left, a numeric field on the right.
class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.label,
    required this.controller,
    this.hint,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppRow(
      title: label,
      trailing: SizedBox(
        width: 140,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.right,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => onSubmitted?.call(),
          style: TextStyle(fontSize: 15.5, color: t.label),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

/// Copy and Share for a result.
class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: l10n?.copy ?? 'Copy',
            icon: Icons.copy_rounded,
            kind: AppButtonKind.tinted,
            compact: true,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              context.showToast(
                l10n?.copied ?? 'Copied',
                kind: AppToastKind.success,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            label: l10n?.share ?? 'Share',
            icon: context.isClearStyle ? Icons.ios_share : Icons.share_outlined,
            kind: AppButtonKind.tinted,
            compact: true,
            onPressed: () => share(title: title, subject: title, content: text),
          ),
        ),
      ],
    );
  }
}

/// Inline message instead of a snackbar.
class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      text,
      style: TextStyle(fontSize: 13, color: context.tokens.holiday),
    ),
  );
}

/// The facts about one date that every tool reports.
List<AppRow> _dateFacts(BuildContext context, CompleteDate d) {
  final holidays = [
    ...d.allHolidays,
    ...d.allAnniversaryDays,
  ].map(_t).join(', ');
  final astro = d.astrologicalDays.map(_t).join(', ');
  final l10n = AppLocalizations.of(context);
  return [
    AppRow(
      title: l10n?.weekday ?? 'Weekday',
      value: TranslationService.getWeekdayName(d.weekday, _language),
    ),
    AppRow(
      leading: MoonGlyph(date: _dateOf(d), size: 24),
      title: l10n?.moon ?? 'Moon',
      value: TranslationService.getMoonPhaseName(d.moonPhase, _language),
    ),
    AppRow(
      title: l10n?.holidays ?? 'Holidays',
      subtitle: holidays.isEmpty ? l10n?.none ?? 'None' : holidays,
    ),
    if (astro.isNotEmpty)
      AppRow(title: l10n?.astrology ?? 'Astrology', subtitle: astro),
  ];
}

String _factsText(BuildContext context, CompleteDate d) {
  final holidays = [...d.allHolidays, ...d.allAnniversaryDays].map(_t);
  final l10n = AppLocalizations.of(context);
  return [
    '${l10n?.weekday ?? 'Weekday'}: ${TranslationService.getWeekdayName(d.weekday, _language)}',
    '${l10n?.moon ?? 'Moon'}: ${TranslationService.getMoonPhaseName(d.moonPhase, _language)}',
    if (holidays.isNotEmpty)
      '${l10n?.holidays ?? 'Holidays'}: ${holidays.join(', ')}',
    if (d.astrologicalDays.isNotEmpty)
      '${l10n?.astrology ?? 'Astrology'}: ${d.astrologicalDays.map(_t).join(', ')}',
  ].join('\n');
}

List<Widget> _spaced(List<Widget> children) => [
  for (final (i, child) in children.indexed) ...[
    if (i > 0) const SizedBox(height: 18),
    child,
  ],
];

// ─────────────────────────────── Convert ───────────────────────────────

class ConvertTool extends StatefulWidget {
  const ConvertTool({super.key});

  @override
  State<ConvertTool> createState() => _ConvertToolState();
}

class _ConvertToolState extends State<ConvertTool> {
  final AnalyticsPort _analytics = getIt<AnalyticsPort>();
  bool _westernToMyanmar = true;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  final _year = TextEditingController();
  final _month = TextEditingController();
  final _day = TextEditingController();
  ConversionResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _convert());
  }

  @override
  void dispose() {
    _year.dispose();
    _month.dispose();
    _day.dispose();
    super.dispose();
  }

  void _convert() {
    if (!mounted) return;
    _analytics.logButtonClick(
      buttonName: 'convert',
      buttonLocation: 'date_converter_card',
    );
    if (_westernToMyanmar) {
      context.read<ConverterBloc>().add(ConvertWesternToMyanmarEvent(_date));
      return;
    }
    final year = int.tryParse(_year.text);
    final month = int.tryParse(_month.text);
    final day = int.tryParse(_day.text);
    final l10n = AppLocalizations.of(context);
    if (year == null || month == null || day == null) {
      setState(
        () => _error =
            l10n?.converterEnterMyanmarDate ??
            'Enter a Myanmar year, month and day.',
      );
      return;
    }
    if (month > 14 || day < 1 || day > 30) {
      setState(
        () => _error =
            l10n?.converterMonthDayRange ?? 'Month is 0–14 and day is 1–30.',
      );
      return;
    }
    setState(() => _error = null);
    context.read<ConverterBloc>().add(
      ConvertMyanmarToWesternEvent(year, month, day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<ConverterBloc, ConverterState>(
      listenWhen: (_, s) => s is ConversionSuccess || s is ConversionError,
      listener: (context, state) => setState(() {
        if (state is ConversionSuccess) {
          _result = state.result;
          _error = null;
        } else if (state is ConversionError) {
          _error = state.message;
        }
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _spaced([
          AppSegmented<bool>(
            segments: {
              true: l10n?.converterWesternToMyanmar ?? 'Western → Myanmar',
              false: l10n?.converterMyanmarToWestern ?? 'Myanmar → Western',
            },
            value: _westernToMyanmar,
            onChanged: (v) => setState(() {
              _westernToMyanmar = v;
              _result = null;
              _error = null;
              if (v) _convert();
            }),
          ),
          if (_westernToMyanmar)
            AppGroup(
              children: [
                _DateRow(
                  label: l10n?.date ?? 'Date',
                  date: _date,
                  onChanged: (d) {
                    setState(() => _date = d);
                    _convert();
                  },
                ),
              ],
            )
          else ...[
            AppGroup(
              footer:
                  l10n?.converterMonthFooter ??
                  'Month: 0 = First Waso, 1–12 = Tagu to Tabaung, '
                      '13 = Late Tagu, 14 = Second Waso.',
              children: [
                _NumberRow(
                  label: l10n?.year ?? 'Year',
                  controller: _year,
                  hint: '1388',
                ),
                _NumberRow(
                  label: l10n?.month ?? 'Month',
                  controller: _month,
                  hint: '0–14',
                ),
                _NumberRow(
                  label: l10n?.day ?? 'Day',
                  controller: _day,
                  hint: '1–30',
                  onSubmitted: _convert,
                ),
              ],
            ),
            AppButton(label: l10n?.convert ?? 'Convert', onPressed: _convert),
          ],
          if (_error != null) _Message(_error!),
          if (_result case final result?) ..._resultSection(context, result),
        ]),
      ),
    );
  }

  List<Widget> _resultSection(BuildContext context, ConversionResult result) {
    final d = result.completeDate;
    final headline = _westernToMyanmar
        ? result.formattedMyanmar
        : _fullDate(context, _dateOf(d));
    final other = _westernToMyanmar
        ? _fullDate(context, _dateOf(d))
        : result.formattedMyanmar;
    final l10n = AppLocalizations.of(context);
    return [
      AppGroup(
        label: l10n?.converterResult ?? 'Result',
        children: [
          AppRow(title: headline, subtitle: other),
          ..._dateFacts(context, d),
        ],
      ),
      _ResultActions(
        title: l10n?.converterConvertedDate ?? 'Converted date',
        text: '$headline\n$other\n${_factsText(context, d)}',
      ),
    ];
  }
}

// ────────────────────────────── Difference ──────────────────────────────

class DifferenceTool extends StatefulWidget {
  const DifferenceTool({super.key});

  @override
  State<DifferenceTool> createState() => _DifferenceToolState();
}

class _DifferenceToolState extends State<DifferenceTool> {
  DateTime _start = DateUtils.dateOnly(DateTime.now());
  DateTime _end = DateUtils.dateOnly(
    DateTime.now().add(const Duration(days: 30)),
  );
  DateCalculationResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculate());
  }

  void _calculate() {
    if (!mounted) return;
    getIt<AnalyticsPort>().logButtonClick(
      buttonName: 'calculate_difference',
      buttonLocation: 'date_calculator_card',
    );
    context.read<ConverterBloc>().add(
      CalculateDateDifferenceEvent(_start, _end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context);
    return BlocListener<ConverterBloc, ConverterState>(
      listenWhen: (_, s) => s is CalculationSuccess || s is CalculationError,
      listener: (context, state) => setState(() {
        if (state is CalculationSuccess) {
          _result = state.result;
          _error = null;
        } else if (state is CalculationError) {
          _error = state.message;
        }
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _spaced([
          AppGroup(
            children: [
              _DateRow(
                label: l10n?.converterStart ?? 'Start',
                date: _start,
                onChanged: (d) {
                  setState(() => _start = d);
                  _calculate();
                },
              ),
              _DateRow(
                label: l10n?.converterEnd ?? 'End',
                date: _end,
                onChanged: (d) {
                  setState(() => _end = d);
                  _calculate();
                },
              ),
              AppRow(
                title: l10n?.converterSwapDates ?? 'Swap dates',
                tone: AppRowTone.accent,
                onTap: () {
                  setState(() {
                    final start = _start;
                    _start = _end;
                    _end = start;
                  });
                  _calculate();
                },
              ),
              AppRow(
                title: l10n?.converterStartFromToday ?? 'Start from today',
                tone: AppRowTone.accent,
                onTap: () {
                  setState(() => _start = DateUtils.dateOnly(DateTime.now()));
                  _calculate();
                },
              ),
            ],
          ),
          if (_error != null) _Message(_error!),
          if (_result case final result?) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  children: [
                    Text(
                      translateNumbers('${result.totalDays}'),
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      l10n?.converterDaysUnit(result.totalDays) ??
                          (result.totalDays == 1 ? 'day' : 'days'),
                      style: TextStyle(color: t.secondaryLabel),
                    ),
                  ],
                ),
              ),
            ),
            AppGroup(
              footer: result.formattedDifference,
              children: [
                AppRow(
                  title: l10n?.years ?? 'Years',
                  value: translateNumbers('${result.years}'),
                ),
                AppRow(
                  title: l10n?.months ?? 'Months',
                  value: translateNumbers('${result.months}'),
                ),
                AppRow(
                  title: l10n?.weeks ?? 'Weeks',
                  value: translateNumbers('${result.weeks}'),
                ),
                AppRow(
                  title: l10n?.days ?? 'Days',
                  value: translateNumbers('${result.days}'),
                ),
              ],
            ),
            _ResultActions(
              title: l10n?.converterDateDifference ?? 'Date difference',
              text:
                  '${_fullDate(context, _start)} → ${_fullDate(context, _end)}\n'
                  '${result.totalDays} '
                  '${l10n?.converterDaysUnit(result.totalDays) ?? 'days'} '
                  '(${result.formattedDifference})',
            ),
          ],
        ]),
      ),
    );
  }
}

// ───────────────────────────── Add / Subtract ─────────────────────────────

class ArithmeticTool extends StatefulWidget {
  const ArithmeticTool({super.key});

  @override
  State<ArithmeticTool> createState() => _ArithmeticToolState();
}

class _ArithmeticToolState extends State<ArithmeticTool> {
  DateTime _start = DateUtils.dateOnly(DateTime.now());
  String _operation = 'add';
  String _unit = 'days';
  final _value = TextEditingController(text: '30');
  DateArithmeticResult? _result;
  String? _error;

  Map<String, String> _units(AppLocalizations? l10n) => {
    'days': l10n?.days ?? 'Days',
    'weeks': l10n?.weeks ?? 'Weeks',
    'months': l10n?.months ?? 'Months',
    'years': l10n?.years ?? 'Years',
  };

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _calculate() {
    final value = int.tryParse(_value.text);
    if (value == null || value <= 0) {
      final l10n = AppLocalizations.of(context);
      setState(
        () => _error =
            l10n?.converterEnterWholeNumber ?? 'Enter a whole number above 0.',
      );
      return;
    }
    setState(() => _error = null);
    getIt<AnalyticsPort>().logButtonClick(
      buttonName: 'calculate_arithmetic',
      buttonLocation: 'date_arithmetic_card',
    );
    context.read<ConverterBloc>().add(
      PerformDateArithmeticEvent(
        startDate: _start,
        operation: _operation,
        value: value,
        unit: _unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = _result == null
        ? ''
        : l10n?.converterUnit(_result!.unit) ?? _result!.unit;
    return BlocListener<ConverterBloc, ConverterState>(
      listenWhen: (_, s) => s is ArithmeticSuccess || s is ArithmeticError,
      listener: (context, state) => setState(() {
        if (state is ArithmeticSuccess) {
          _result = state.result;
          _error = null;
        } else if (state is ArithmeticError) {
          _error = state.message;
        }
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _spaced([
          AppGroup(
            children: [
              _DateRow(
                label: l10n?.converterStart ?? 'Start',
                date: _start,
                onChanged: (d) => setState(() => _start = d),
              ),
              _NumberRow(
                label: l10n?.converterValue ?? 'Value',
                controller: _value,
                onSubmitted: _calculate,
              ),
            ],
          ),
          AppSegmented<String>(
            segments: {
              'add': l10n?.add ?? 'Add',
              'subtract': l10n?.converterSubtract ?? 'Subtract',
            },
            value: _operation,
            onChanged: (v) => setState(() => _operation = v),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(:key, :value) in _units(l10n).entries)
                AppChip(
                  label: value,
                  selected: _unit == key,
                  onSelected: (_) => setState(() => _unit = key),
                ),
            ],
          ),
          AppButton(
            label: l10n?.calculate ?? 'Calculate',
            onPressed: _calculate,
          ),
          if (_error != null) _Message(_error!),
          if (_result case final result?) ...[
            AppGroup(
              label:
                  '${result.operation == 'add' ? '+' : '−'}${result.value} $unit',
              children: [
                AppRow(
                  title: _fullDate(context, _dateOf(result.resultDate)),
                  subtitle: _myanmar(result.resultDate.myanmar),
                ),
                ..._dateFacts(context, result.resultDate),
              ],
            ),
            _ResultActions(
              title: l10n?.converterDateArithmetic ?? 'Date arithmetic',
              text:
                  '${_fullDate(context, _start)} '
                  '${result.operation == 'add' ? '+' : '−'} '
                  '${result.value} $unit = '
                  '${_fullDate(context, _dateOf(result.resultDate))}\n'
                  '${_myanmar(result.resultDate.myanmar)}\n'
                  '${_factsText(context, result.resultDate)}',
            ),
          ],
        ]),
      ),
    );
  }
}

// ──────────────────────────────── Moon ────────────────────────────────

class MoonFinderTool extends StatefulWidget {
  const MoonFinderTool({super.key});

  @override
  State<MoonFinderTool> createState() => _MoonFinderToolState();
}

class _MoonFinderToolState extends State<MoonFinderTool> {
  DateTime _from = DateUtils.dateOnly(DateTime.now());
  int _phase = 1;
  MoonPhaseResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _find());
  }

  void _find() {
    if (!mounted) return;
    getIt<AnalyticsPort>().logButtonClick(
      buttonName: 'find_moon_phase',
      buttonLocation: 'moon_phase_finder_card',
    );
    context.read<ConverterBloc>().add(FindNextMoonPhaseEvent(_from, _phase));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context);
    return BlocListener<ConverterBloc, ConverterState>(
      listenWhen: (_, s) => s is MoonPhaseSuccess || s is MoonPhaseError,
      listener: (context, state) => setState(() {
        if (state is MoonPhaseSuccess) {
          _result = state.result;
          _error = null;
        } else if (state is MoonPhaseError) {
          _error = state.message;
        }
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _spaced([
          AppGroup(
            children: [
              _DateRow(
                label: l10n?.converterFrom ?? 'From',
                date: _from,
                onChanged: (d) {
                  setState(() => _from = d);
                  _find();
                },
              ),
            ],
          ),
          AppSegmented<int>(
            segments: {
              for (final phase in const [0, 1, 2, 3])
                phase: TranslationService.getMoonPhaseName(phase, _language),
            },
            value: _phase,
            onChanged: (v) {
              setState(() => _phase = v);
              _find();
            },
          ),
          if (_error != null) _Message(_error!),
          if (_result case final result?) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    MoonGlyph(date: _dateOf(result.dateFound), size: 56),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.converterNextPhase(result.moonPhaseName) ??
                                'Next ${result.moonPhaseName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${_fullDate(context, _dateOf(result.dateFound))} · '
                            '${result.daysFromStart == 0 ? l10n?.converterTodayLower ?? 'today' : l10n?.converterInDays(result.daysFromStart) ?? 'in ${result.daysFromStart} ${result.daysFromStart == 1 ? 'day' : 'days'}'}',
                            style: TextStyle(color: t.secondaryLabel),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppGroup(
              children: [
                AppRow(
                  title: l10n?.converterMyanmarDate ?? 'Myanmar date',
                  subtitle: _myanmar(result.dateFound.myanmar),
                ),
                ..._dateFacts(context, result.dateFound),
              ],
            ),
            _ResultActions(
              title: l10n?.converterMoonPhase ?? 'Moon phase',
              text:
                  '${l10n?.converterNextPhase(result.moonPhaseName) ?? 'Next ${result.moonPhaseName}'}: '
                  '${_fullDate(context, _dateOf(result.dateFound))} '
                  '(${l10n?.converterInDays(result.daysFromStart) ?? 'in ${result.daysFromStart} days'})\n'
                  '${_myanmar(result.dateFound.myanmar)}',
            ),
          ],
        ]),
      ),
    );
  }
}

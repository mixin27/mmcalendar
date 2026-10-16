import 'package:flutter/material.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../services/calendar_studio_cache.dart';
import '../services/calendar_studio_contracts.dart';

/// Legend items a themed legend can show, in display order.
enum StudioLegendItem {
  holiday('ပိတ်ရက်', 'Public holiday'),
  sabbath('ဥပုသ်', 'Sabbath'),
  fullMoon('လပြည့်', 'Full moon'),
  newMoon('လကွယ်', 'New moon'),
  events('ပွဲ', 'Events');

  const StudioLegendItem(this.myanmar, this.english);
  final String myanmar;
  final String english;
}

Color? _color(Object? value) => value is int ? Color(value) : null;

/// Theme-coloured legend with a swatch per item.
///
/// `content.items` lists [StudioLegendItem] names in the order to show them;
/// items whose data the project hides (holidays, moon phases, events) are
/// dropped. Text wraps onto two lines and scales down to fit the box rather
/// than overflowing.
class StudioThemedLegend extends StatelessWidget {
  const StudioThemedLegend({
    required this.block,
    required this.source,
    super.key,
  });
  final CalendarStudioBlock block;
  final CalendarStudioSource source;

  List<StudioLegendItem> get _items {
    final names = (block.content['items'] as List?)?.whereType<String>();
    final items = names == null
        ? StudioLegendItem.values
        : [
            for (final name in names)
              ?StudioLegendItem.values.asNameMap()[name],
          ];
    return [
      for (final item in items)
        if (switch (item) {
          StudioLegendItem.holiday => source.showHolidays,
          StudioLegendItem.sabbath => source.showMyanmarDate,
          StudioLegendItem.fullMoon ||
          StudioLegendItem.newMoon => source.showMoonPhases,
          StudioLegendItem.events => source.showEvents,
        })
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final style = block.style;
    final ink = _color(style['inkColor']) ?? const Color(0xFF15201D);
    final muted = _color(style['mutedColor']) ?? ink.withValues(alpha: .6);
    final size = (style['fontSize'] as num?)?.toDouble() ?? 10;
    final align = switch (style['align']) {
      'center' => WrapAlignment.center,
      'right' => WrapAlignment.end,
      _ => WrapAlignment.start,
    };
    Color swatch(StudioLegendItem item) => switch (item) {
      StudioLegendItem.holiday =>
        _color(style['holidayColor']) ?? const Color(0xFFB8322A),
      StudioLegendItem.sabbath =>
        _color(style['sabbathColor']) ?? const Color(0xFF8A6210),
      StudioLegendItem.fullMoon =>
        _color(style['moonColor']) ?? const Color(0xFFD9A93A),
      StudioLegendItem.newMoon => muted,
      StudioLegendItem.events =>
        _color(style['eventColor']) ?? const Color(0xFF0E6B5C),
    };
    String label(StudioLegendItem item) => switch (source.language) {
      CalendarStudioLanguage.myanmar => item.myanmar,
      CalendarStudioLanguage.english => item.english,
      CalendarStudioLanguage.both => '${item.myanmar}  ${item.english}',
    };
    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: switch (style['align']) {
          'center' => Alignment.center,
          'right' => Alignment.centerRight,
          _ => Alignment.centerLeft,
        },
        child: SizedBox(
          width: constraints.maxWidth,
          child: Wrap(
            alignment: align,
            spacing: size * 1.6,
            runSpacing: size * .5,
            children: [
              for (final item in _items)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Swatch(
                      color: swatch(item),
                      outlined: item == StudioLegendItem.newMoon,
                      bar: item == StudioLegendItem.events,
                      size: size * .8,
                    ),
                    SizedBox(width: size * .45),
                    Text(
                      label(item),
                      style: TextStyle(
                        fontSize: size,
                        height: 1.6,
                        color: ink,
                        fontFamily: style['fontFamily'] as String?,
                        fontFamilyFallback: const ['Noto Sans Myanmar'],
                      ),
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

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.size,
    this.outlined = false,
    this.bar = false,
  });
  final Color color;
  final double size;
  final bool outlined;
  final bool bar;

  @override
  Widget build(BuildContext context) => Container(
    width: bar ? size * 1.8 : size,
    height: bar ? size * .4 : size,
    decoration: BoxDecoration(
      color: outlined ? null : color,
      shape: bar ? BoxShape.rectangle : BoxShape.circle,
      borderRadius: bar ? BorderRadius.circular(size) : null,
      border: outlined ? Border.all(color: color, width: 1.2) : null,
    ),
  );
}

/// A titled list for a page's month: real events when the project shows
/// them, otherwise the preset's placeholder rows (or ruled lines for notes).
/// Rows that don't fit are left out instead of being clipped mid-line.
class StudioEventList extends StatefulWidget {
  const StudioEventList({
    required this.block,
    required this.source,
    this.dataProvider,
    this.resolvedDays,
    super.key,
  });
  final CalendarStudioBlock block;
  final CalendarStudioSource source;
  final CalendarStudioDataProvider? dataProvider;
  final List<CalendarStudioDayData>? resolvedDays;

  @override
  State<StudioEventList> createState() => _StudioEventListState();
}

class _StudioEventListState extends State<StudioEventList> {
  Future<List<CalendarStudioDayData>>? _days;
  List<CalendarStudioDayData>? _cached;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant StudioEventList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.dataProvider != widget.dataProvider) {
      _prepare();
    }
  }

  void _prepare() {
    final provider = widget.dataProvider;
    final source = widget.source;
    _cached = provider is CachedCalendarStudioDataProvider
        ? provider.peek(source, month: source.month)
        : null;
    _days = _cached != null || provider == null || !source.showEvents
        ? null
        : provider.daysFor(source, month: source.month);
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.resolvedDays ?? _cached;
    if (days != null || _days == null) return _list(days);
    return FutureBuilder<List<CalendarStudioDayData>>(
      future: _days,
      builder: (_, snapshot) => _list(snapshot.data),
    );
  }

  Widget _list(List<CalendarStudioDayData>? days) {
    final block = widget.block;
    final style = block.style;
    final ink = _color(style['inkColor']) ?? const Color(0xFF15201D);
    final muted = _color(style['mutedColor']) ?? ink.withValues(alpha: .6);
    final titleColor = _color(style['titleColor']) ?? ink;
    final lineColor = _color(style['lineColor']) ?? ink.withValues(alpha: .2);
    final size = (style['fontSize'] as num?)?.toDouble() ?? 10;
    final family = style['fontFamily'] as String?;
    final notes = block.content['kind'] == 'notes';
    final real = [
      if (widget.source.showEvents && days != null)
        for (final day in days)
          for (final event in day.events) '${day.date.day} — $event',
    ];
    final placeholder =
        (block.content['placeholder'] as List?)?.whereType<String>().toList() ??
        const <String>[];
    final rows = real.isNotEmpty ? real : placeholder;
    final title = block.content['title'] as String?;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowHeight = size * 1.9;
        final titleHeight = title == null ? 0.0 : size * 2.2;
        final fit = ((constraints.maxHeight - titleHeight) / rowHeight)
            .floor()
            .clamp(0, 50);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              SizedBox(
                height: titleHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: size * 1.05,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                      color: titleColor,
                      fontFamily: family,
                      fontFamilyFallback: const ['Noto Sans Myanmar'],
                    ),
                  ),
                ),
              ),
            for (var i = 0; i < fit; i++)
              Container(
                height: rowHeight,
                alignment: Alignment.centerLeft,
                decoration: notes
                    ? BoxDecoration(
                        border: Border(bottom: BorderSide(color: lineColor)),
                      )
                    : null,
                child: notes || i >= rows.length
                    ? null
                    : Text(
                        rows[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: size,
                          height: 1.4,
                          color: real.isNotEmpty ? ink : muted,
                          fontFamily: family,
                          fontFamilyFallback: const ['Noto Sans Myanmar'],
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}

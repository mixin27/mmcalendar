import 'package:flutter/material.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../services/calendar_studio_contracts.dart';

/// The single Flutter render path for editable canvases and page previews.
class CalendarStudioScene extends StatelessWidget {
  const CalendarStudioScene({
    required this.page,
    required this.source,
    this.selectedBlockId,
    this.showSafeArea = false,
    this.onSelect,
    this.dataProvider,
    super.key,
  });
  final CalendarStudioPage page;
  final CalendarStudioSource source;
  final String? selectedBlockId;
  final bool showSafeArea;
  final ValueChanged<CalendarStudioBlock?>? onSelect;
  final CalendarStudioDataProvider? dataProvider;

  @override
  Widget build(BuildContext context) {
    final blocks = [...page.blocks]
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return AspectRatio(
      aspectRatio: page.canvas.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) => DecoratedBox(
          decoration: BoxDecoration(color: Color(page.canvas.backgroundColor)),
          child: Stack(
            children: [
              for (final block in blocks)
                if (block.visible)
                  _buildBlock(context, constraints.biggest, block),
              if (showSafeArea)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.all(
                        constraints.maxWidth * page.canvas.safeInset,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .75),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(
    BuildContext context,
    Size size,
    CalendarStudioBlock block,
  ) {
    final rect = block.bounds.resolve(size);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTap: () => onSelect?.call(block),
        child: Transform.rotate(
          angle: block.rotation,
          child: DecoratedBox(
            decoration: selectedBlockId == block.id
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  )
                : const BoxDecoration(),
            child: _contents(block),
          ),
        ),
      ),
    );
  }

  Widget _contents(CalendarStudioBlock block) => switch (block.type) {
    CalendarStudioBlockType.calendarGrid => _CalendarGrid(
      source: source.copyWith(year: page.year, month: page.month),
      dataProvider: dataProvider,
    ),
    CalendarStudioBlockType.text => _TextBlock(block: block),
    CalendarStudioBlockType.shape => ColoredBox(
      color: Color((block.style['color'] as int?) ?? 0xFF0E6B5C),
    ),
    CalendarStudioBlockType.image ||
    CalendarStudioBlockType.logo => DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE1E8E4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Icon(Icons.image_outlined)),
    ),
    CalendarStudioBlockType.eventList => const _ListBlock(
      icon: Icons.event_outlined,
      label: 'My events',
    ),
    CalendarStudioBlockType.holidayLegend => const _ListBlock(
      icon: Icons.local_offer_outlined,
      label: 'Holiday legend',
    ),
    CalendarStudioBlockType.decoration => const Center(
      child: Icon(Icons.spa_outlined, color: Color(0xFFB98A25)),
    ),
  };
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.block});
  final CalendarStudioBlock block;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: switch (block.style['align']) {
      'center' => Alignment.center,
      'right' => Alignment.centerRight,
      _ => Alignment.centerLeft,
    },
    child: Text(
      (block.content['text'] as String?) ?? '',
      textAlign: switch (block.style['align']) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        _ => TextAlign.left,
      },
      style: TextStyle(
        fontFamily: 'Noto Serif Myanmar',
        fontSize: (block.style['fontSize'] as num?)?.toDouble() ?? 20,
        fontWeight: FontWeight.w700,
        color: Color((block.style['color'] as int?) ?? 0xFF15201D),
      ),
    ),
  );
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 5),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
    ],
  );
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.source, this.dataProvider});
  final CalendarStudioSource source;
  final CalendarStudioDataProvider? dataProvider;
  @override
  Widget build(BuildContext context) {
    final date = DateTime(source.year, source.month);
    final first =
        (date.weekday % 7 - (source.weekStartsMonday ? 1 : 0) + 7) % 7;
    final count = DateUtils.getDaysInMonth(source.year, source.month);
    final headers = source.weekStartsMonday
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    Widget buildGrid(List<CalendarStudioDayData>? dayData) => Column(
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            physics: const NeverScrollableScrollPhysics(),
            children: headers
                .map(
                  (value) => Center(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          flex: 5,
          child: GridView.count(
            crossAxisCount: 7,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(first + count, (index) {
              final day = index - first + 1;
              if (day < 1) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.all(1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF15201D).withValues(alpha: .18),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text(
                      dayData == null || !source.showMyanmarDate
                          ? '$day'
                          : '${dayData[day - 1].gregorianLabel}\n${dayData[day - 1].myanmarLabel ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
    if (dataProvider == null) return buildGrid(null);
    return FutureBuilder<List<CalendarStudioDayData>>(
      future: dataProvider!.daysFor(source, month: source.month),
      builder: (_, snapshot) => buildGrid(snapshot.data),
    );
  }
}

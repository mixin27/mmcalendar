import 'package:flutter/material.dart';

/// Years Studio offers: the range the app's month picker uses and the
/// calendar data covers with holidays.
const calendarStudioFirstYear = 1900;
const calendarStudioLastYear = 2100;

/// A "Year" field that opens a grid of every year from
/// [calendarStudioFirstYear] to [calendarStudioLastYear], scrolled to the
/// current one.
class CalendarStudioYearField extends StatelessWidget {
  const CalendarStudioYearField({
    super.key,
    required this.year,
    required this.onChanged,
    this.label = 'Year',
  });

  final int year;
  final ValueChanged<int> onChanged;
  final String label;

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .7,
        child: _YearGrid(selected: year),
      ),
    );
    if (picked != null && picked != year) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('calendar-studio-year-field'),
    borderRadius: BorderRadius.circular(4),
    onTap: () => _pick(context),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      child: Text('$year'),
    ),
  );
}

class _YearGrid extends StatefulWidget {
  const _YearGrid({required this.selected});
  final int selected;

  @override
  State<_YearGrid> createState() => _YearGridState();
}

class _YearGridState extends State<_YearGrid> {
  static const _columns = 4;
  static const _rowHeight = 52.0;
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final row =
        (widget.selected.clamp(
              calendarStudioFirstYear,
              calendarStudioLastYear,
            ) -
            calendarStudioFirstYear) ~/
        _columns;
    _scroll = ScrollController(
      initialScrollOffset: ((row - 2) * _rowHeight).clamp(0, double.infinity),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const count = calendarStudioLastYear - calendarStudioFirstYear + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text('Year', style: Theme.of(context).textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Holiday data is most complete from 1950 on.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: count,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              mainAxisExtent: _rowHeight - 8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final year = calendarStudioFirstYear + index;
              final selected = year == widget.selected;
              return Material(
                color: selected ? scheme.primary : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: ValueKey('calendar-studio-year-$year'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context, year),
                  child: Center(
                    child: Text(
                      '$year',
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? scheme.onPrimary : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

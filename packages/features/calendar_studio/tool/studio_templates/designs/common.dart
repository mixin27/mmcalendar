import '../design.dart';
import '../page_builder.dart';

/// [months] text for [month], or [generic] on the template page.
String pick(
  DesignContext context,
  int month,
  List<String> months,
  String generic,
) => context.template ? generic : months[month - 1];

/// Date rows for [month], or [generic] on the template page.
List<String> rowsFor(
  DesignContext context,
  int month,
  Map<int, List<String>> months,
  List<String> generic, {
  List<String> fallback = const ['__ — ________'],
}) => context.template ? generic : (months[month] ?? fallback);

/// Special days most couples and friends share; the rest are blanks.
const sharedDates = {
  1: ['1 — New Year\'s Day', '__ — ________'],
  2: ['14 — Valentine\'s Day', '__ — ________'],
  4: ['Thingyan holidays', '__ — ________'],
  12: ['25 — Christmas', '31 — New Year\'s Eve'],
};

/// The square grid and legend, under the top 45% of the page.
void squareGrid(
  PageBuilder page, {
  String gridLines = 'none',
  String numbers = 'Fraunces',
  int? weekend,
}) {
  page
    ..grid(
      [0.06, 0.47, 0.88, 0.435],
      gridLines: gridLines,
      numberFamily: numbers,
      weekend: weekend,
    )
    ..legend([0.06, 0.925, 0.88, 0.035]);
}

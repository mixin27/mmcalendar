import 'package:flutter/material.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_page_model.dart';

class CalendarGenerationPreviewPage extends StatelessWidget {
  const CalendarGenerationPreviewPage({
    required this.model,
    required this.request,
    super.key,
  });

  final CalendarPageModel model;
  final CalendarGenerationRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = request.theme;
    final backgroundColor = Color(theme.backgroundColorValue);
    final foregroundColor = Color(theme.foregroundColorValue);
    final accentColor = Color(theme.accentColorValue);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 2,
      child: AspectRatio(
        aspectRatio: 1 / 1.414,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            image:
                (theme.backgroundImageUrl != null &&
                    theme.backgroundImageUrl!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(theme.backgroundImageUrl!),
                    fit: BoxFit.cover,
                    opacity: 0.18,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  model.title,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _WeekdayHeader(
                  labels: model.weekdayLabels,
                  foregroundColor: foregroundColor,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: GridView.builder(
                    itemCount: model.dayCells.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.86,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                    itemBuilder: (context, index) {
                      final day = model.dayCells[index];
                      final hasMarker =
                          (request.showHolidays && day.hasHoliday) ||
                          (request.showAstrology && day.hasAstrology);

                      return Container(
                        decoration: BoxDecoration(
                          color: day.isCurrentMonth
                              ? backgroundColor.withValues(alpha: 0.92)
                              : foregroundColor.withValues(alpha: 0.06),
                          border: Border.all(
                            color: day.isToday
                                ? accentColor
                                : foregroundColor.withValues(alpha: 0.15),
                            width: day.isToday ? 1.3 : 0.6,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Stack(
                          children: [
                            if (request.showWesternDates)
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  day.westernDayLabel,
                                  style: TextStyle(
                                    color: foregroundColor.withValues(
                                      alpha: day.isCurrentMonth ? 0.95 : 0.5,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (request.showMyanmarDates)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  day.myanmarDayLabel,
                                  style: TextStyle(
                                    color: foregroundColor.withValues(
                                      alpha: day.isCurrentMonth ? 0.78 : 0.45,
                                    ),
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            if (hasMarker)
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
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

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.labels, required this.foregroundColor});

  final List<String> labels;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foregroundColor.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

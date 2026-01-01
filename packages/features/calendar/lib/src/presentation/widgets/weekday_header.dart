import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class WeekdayHeader extends StatelessWidget {
  final int firstDayOfWeek;
  final Language language;

  const WeekdayHeader({
    super.key,
    this.firstDayOfWeek = 1,
    this.language = Language.english,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: List.generate(7, (index) {
          final myanmarWeekdayIndex = (firstDayOfWeek + index) % 7;
          final weekdayName = TranslationService.getShortWeekdayName(
            myanmarWeekdayIndex,
            language,
          );
          final isWeekend =
              myanmarWeekdayIndex == 0 || myanmarWeekdayIndex == 1;

          return Expanded(
            child: Semantics(
              label: TranslationService.getWeekdayName(myanmarWeekdayIndex),
              child: Text(
                weekdayName,
                textAlign: TextAlign.center,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isWeekend
                      ? context.colorScheme.primary
                      : context.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

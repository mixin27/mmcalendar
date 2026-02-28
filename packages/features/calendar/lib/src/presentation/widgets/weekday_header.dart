import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

enum _WeekdayLabelDensity { short, narrow, numeric }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final cellWidth = constraints.maxWidth / 7;
        final adjustedCellWidth = cellWidth / textScale;
        final density = _resolveDensity(adjustedCellWidth);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: List.generate(7, (index) {
              final myanmarWeekdayIndex = (firstDayOfWeek + index) % 7;
              final weekdayName = _getWeekdayLabel(
                myanmarWeekdayIndex,
                density,
              );
              final isWeekend =
                  myanmarWeekdayIndex == 0 || myanmarWeekdayIndex == 1;

              return Expanded(
                child: Semantics(
                  label: TranslationService.getWeekdayName(
                    myanmarWeekdayIndex,
                    language,
                  ),
                  child: Tooltip(
                    message: TranslationService.getWeekdayName(
                      myanmarWeekdayIndex,
                      language,
                    ),
                    child: Text(
                      weekdayName,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isWeekend
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  _WeekdayLabelDensity _resolveDensity(double adjustedCellWidth) {
    if (adjustedCellWidth >= 40) {
      return _WeekdayLabelDensity.short;
    }
    if (adjustedCellWidth >= 30) {
      return _WeekdayLabelDensity.narrow;
    }
    return _WeekdayLabelDensity.numeric;
  }

  String _getWeekdayLabel(int weekdayIndex, _WeekdayLabelDensity density) {
    switch (density) {
      case _WeekdayLabelDensity.short:
        final shortName = _getPreferredShortLabel(weekdayIndex);
        if (shortName.isNotEmpty) {
          return shortName;
        }
        return _getNarrowWeekdayLabel(weekdayIndex);
      case _WeekdayLabelDensity.narrow:
        return _getNarrowWeekdayLabel(weekdayIndex);
      case _WeekdayLabelDensity.numeric:
        return _getWeekdayNumberLabel(weekdayIndex);
    }
  }

  String _getNarrowWeekdayLabel(int weekdayIndex) {
    if (language == Language.english) {
      return switch (weekdayIndex) {
        1 => 'S',
        2 => 'M',
        3 => 'T',
        4 => 'W',
        5 => 'T',
        6 => 'F',
        _ => 'S',
      };
    }

    if (language == Language.myanmar || language == Language.zawgyi) {
      return switch (weekdayIndex) {
        1 => 'နွေ',
        2 => 'လာ',
        3 => 'ဂါ',
        4 => 'ဟူး',
        5 => 'ကြာ',
        6 => 'သော',
        _ => 'စ',
      };
    }

    return _getWeekdayNumberLabel(weekdayIndex);
  }

  String _getPreferredShortLabel(int weekdayIndex) {
    if (language == Language.english ||
        language == Language.myanmar ||
        language == Language.zawgyi) {
      return _getNarrowWeekdayLabel(weekdayIndex);
      // return TranslationService.getShortWeekdayName(
      //   weekdayIndex,
      //   language,
      // ).trim();
    }

    final fullName = TranslationService.getWeekdayName(
      weekdayIndex,
      language,
    ).trim();
    final stripped = _stripWeekdayPrefix(fullName);
    return stripped.isEmpty ? fullName : stripped;
  }

  String _stripWeekdayPrefix(String text) {
    // Remove shared "day" prefixes for supported scripts so labels remain
    // meaningful instead of one-character abbreviations.
    if (language == Language.mon && text.startsWith('တ္ၚဲ')) {
      return text.replaceFirst('တ္ၚဲ', '').trim();
    }
    if (language == Language.shan && text.startsWith('ဝၼ်း')) {
      return text.replaceFirst('ဝၼ်း', '').trim();
    }
    if (language == Language.karen && text.startsWith('မုၢ်')) {
      return text.replaceFirst('မုၢ်', '').trim();
    }
    return text;
  }

  String _getWeekdayNumberLabel(int weekdayIndex) {
    final value = weekdayIndex == 0 ? 7 : weekdayIndex;
    return FormatService().translateNumbers('$value', language: language);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// Backward-compatible formatting helper for code that used flutter_mmcalendar.
class FormatService {
  String translateNumbers(String text, {Language? language}) {
    final currentLanguage = language ?? MyanmarCalendar.currentLanguage;
    if (!TranslationService.shouldTranslateDigits(currentLanguage)) {
      return text;
    }

    var result = text;
    for (var i = 0; i <= 9; i++) {
      result = result.replaceAll(
        i.toString(),
        TranslationService.translateTo(i.toString(), currentLanguage),
      );
    }
    return result;
  }
}

/// Compatibility extension used by existing UI code.
extension CompleteDateFormattingCompat on CompleteDate {
  String formatMyanmar({String? pattern, Language? language}) {
    return MyanmarCalendar.formatMyanmar(
      myanmar,
      pattern: pattern,
      language: language ?? MyanmarCalendar.currentLanguage,
    );
  }

  String formatWestern({String? pattern, Language? language}) {
    return MyanmarCalendar.formatWestern(
      western,
      pattern: pattern,
      language: language ?? MyanmarCalendar.currentLanguage,
    );
  }
}

/// Compatibility extension used by existing widget code.
extension MyanmarDateFormattingCompat on MyanmarDate {
  String format({String? pattern, Language? language}) {
    return MyanmarCalendar.formatMyanmar(
      this,
      pattern: pattern,
      language: language ?? MyanmarCalendar.currentLanguage,
    );
  }
}

/// Compatibility extension used by existing widget code.
extension WesternDateFormattingCompat on WesternDate {
  String format({String? pattern, Language? language}) {
    return MyanmarCalendar.formatWestern(
      this,
      pattern: pattern,
      language: language ?? MyanmarCalendar.currentLanguage,
    );
  }
}

/// Lightweight batch processor replacement for removed package utility.
class BatchOptimizer {
  static Future<List<R>> processBatch<T, R>(
    List<T> items,
    FutureOr<R> Function(T item) processor, {
    int batchSize = 64,
  }) async {
    if (items.isEmpty) return <R>[];

    final safeBatchSize = batchSize <= 0 ? 64 : batchSize;
    final results = <R>[];

    for (var i = 0; i < items.length; i += safeBatchSize) {
      final end = (i + safeBatchSize < items.length)
          ? i + safeBatchSize
          : items.length;
      final chunk = items.sublist(i, end);
      final chunkResults = await Future.wait<R>(
        chunk.map((item) => Future<R>.sync(() => processor(item))),
      );
      results.addAll(chunkResults);
    }

    return results;
  }
}

/// Keyboard helper replacement for removed Flutter package utility.
class CalendarKeyboardHandler {
  static KeyEventResult handleKeyEvent(
    FocusNode node,
    KeyEvent event, {
    VoidCallback? onArrowUp,
    VoidCallback? onArrowDown,
    VoidCallback? onArrowLeft,
    VoidCallback? onArrowRight,
    VoidCallback? onEnter,
    VoidCallback? onSpace,
    VoidCallback? onHome,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp && onArrowUp != null) {
      onArrowUp();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown && onArrowDown != null) {
      onArrowDown();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft && onArrowLeft != null) {
      onArrowLeft();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight && onArrowRight != null) {
      onArrowRight();
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        onEnter != null) {
      onEnter();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space && onSpace != null) {
      onSpace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home && onHome != null) {
      onHome();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

/// Accessibility label helper replacement for removed Flutter package utility.
class CalendarAccessibility {
  static String generateDateLabel(
    CompleteDate completeDate, {
    Language language = Language.english,
    bool isSelected = false,
    bool isToday = false,
  }) {
    final segments = <String>[];

    if (isToday) {
      segments.add(TranslationService.translateTo('Today', language));
    }
    if (isSelected) {
      segments.add(TranslationService.translateTo('Selected', language));
    }

    segments.add(
      '${TranslationService.getWeekdayName(completeDate.weekday, language)}, '
      '${TranslationService.getWesternMonthName(completeDate.westernMonth, language)} '
      '${completeDate.westernDay}, ${completeDate.westernYear}',
    );
    segments.add(
      MyanmarCalendar.formatMyanmar(completeDate.myanmar, language: language),
    );

    if (completeDate.allHolidays.isNotEmpty) {
      segments.add(
        completeDate.allHolidays
            .map((holiday) => TranslationService.translateTo(holiday, language))
            .join(', '),
      );
    }
    if (completeDate.allAnniversaryDays.isNotEmpty) {
      segments.add(
        completeDate.allAnniversaryDays
            .map((day) => TranslationService.translateTo(day, language))
            .join(', '),
      );
    }

    return segments.where((segment) => segment.isNotEmpty).join('. ');
  }
}

/// Minimal theme container for compatibility with previous picker API.
@immutable
class MyanmarCalendarTheme {
  const MyanmarCalendarTheme({
    required this.primaryColor,
    required this.onPrimaryColor,
  });

  factory MyanmarCalendarTheme.fromColor(Color color, {bool isDark = false}) {
    return MyanmarCalendarTheme(
      primaryColor: color,
      onPrimaryColor: isDark ? Colors.black : Colors.white,
    );
  }

  final Color primaryColor;
  final Color onPrimaryColor;

  ThemeData applyTo(ThemeData baseTheme) {
    final colorScheme = baseTheme.colorScheme.copyWith(
      primary: primaryColor,
      onPrimary: onPrimaryColor,
    );

    return baseTheme.copyWith(colorScheme: colorScheme);
  }
}

/// Drop-in picker replacement that returns a [CompleteDate] for selected day.
Future<CompleteDate?> showMyanmarDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  MyanmarCalendarTheme? theme,
}) async {
  final effectiveFirstDate = firstDate ?? DateTime(1900, 1, 1);
  final effectiveLastDate = lastDate ?? DateTime(2100, 12, 31);
  final clampedInitialDate = initialDate.isBefore(effectiveFirstDate)
      ? effectiveFirstDate
      : initialDate.isAfter(effectiveLastDate)
      ? effectiveLastDate
      : initialDate;
  final baseTheme = Theme.of(context);
  final effectiveTheme =
      theme ??
      MyanmarCalendarTheme.fromColor(
        baseTheme.colorScheme.primary,
        isDark: baseTheme.brightness == Brightness.dark,
      );

  final pickedDate = await showDatePicker(
    context: context,
    initialDate: clampedInitialDate,
    firstDate: effectiveFirstDate,
    lastDate: effectiveLastDate,
    builder: (context, child) {
      return Theme(
        data: effectiveTheme.applyTo(baseTheme),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );

  if (pickedDate == null) {
    return null;
  }

  return MyanmarCalendar.getCompleteDate(
    DateTime(pickedDate.year, pickedDate.month, pickedDate.day),
  );
}

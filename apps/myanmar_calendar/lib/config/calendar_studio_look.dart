import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' show CalendarLanguageContext;
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'calendar_studio_configuration.dart';

/// Studio with the app's current look: Clear or Material chrome, the app
/// colours for this brightness and the app fonts, and new projects in the
/// app's calendar language. Studio stays independent
/// of shared_ui_kit; this adapter is the only place that knows both.
CalendarStudioConfiguration calendarStudioConfigurationFor(
  BuildContext context, {
  CalendarStudioConfiguration? base,
}) {
  final theme = Theme.of(context);
  final t = AppTokens.of(context);
  final studio = calendarStudioTokensFrom(t, theme.brightness);
  return (base ?? calendarStudioConfiguration).withLook(
    // Follow the app's resolved light/dark, not the device's.
    appearance: theme.brightness == Brightness.dark
        ? CalendarStudioAppearance.dark
        : CalendarStudioAppearance.light,
    lightTokens: studio,
    darkTokens: studio,
    chrome: t.isClear
        ? CalendarStudioChrome.clear
        : CalendarStudioChrome.material,
    fontFamily: AppTextStyles.qualifiedFamily,
    fontFamilyFallback: AppTextStyles.qualifiedFallback,
    // New projects start in the app's calendar language.
    defaultLanguage: CalendarStudioLanguageData.fromCalendarLanguage(
      context.calendarLanguage,
    ),
  );
}

CalendarStudioTokens calendarStudioTokensFrom(
  AppTokens t,
  Brightness brightness,
) {
  final base = brightness == Brightness.dark
      ? CalendarStudioTokens.dark
      : CalendarStudioTokens.light;
  Color over(Color top, Color bottom) => Color.alphaBlend(top, bottom);
  final surface2 = over(t.fill, t.surface);
  final board = over(t.fill, t.background);
  return base.copyWith(
    primary: t.accent,
    onPrimary: t.onAccent,
    background: t.background,
    surface: t.surface,
    surface2: surface2,
    surface3: over(t.fill, surface2),
    ink: t.label,
    ink2: t.secondaryLabel,
    ink3: t.tertiaryLabel,
    line: over(t.separator, t.surface),
    holiday: t.holiday,
    gold: t.sabbath,
    ok: t.success,
    error: t.holiday,
    board: board,
    boardInk: t.label,
    board2: over(t.fill, board),
  );
}

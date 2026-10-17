import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../design/app_style.dart';
import '../design/app_tokens.dart';
import 'color_schemes.dart';
import 'text_styles.dart';

/// Builds the app's [ThemeData] for one design style and colour scheme.
///
/// Both styles share colours and type; Clear restyles Material widgets to
/// read as iOS (grouped grey background, flat bars, hairlines, iOS page
/// transitions) while Material keeps Material 3 behaviour.
class AppTheme {
  static const double defaultRadius = 12.0;

  static ThemeData build({
    required AppStyle style,
    required ColorScheme colorScheme,
  }) {
    final resolved = style.resolve();
    final tokens = AppTokens.resolve(style: resolved, scheme: colorScheme);
    return resolved == AppStyle.clear
        ? _clear(colorScheme, tokens)
        : _material(colorScheme, tokens);
  }

  /// Material style with the default scheme for [brightness].
  static ThemeData lightTheme({ColorScheme? customColors}) => build(
    style: AppStyle.material,
    colorScheme: customColors ?? AppColorSchemes.modernLight,
  );

  static ThemeData darkTheme({ColorScheme? customColors}) => build(
    style: AppStyle.material,
    colorScheme: customColors ?? AppColorSchemes.modernDark,
  );

  static ThemeData _base(
    ColorScheme scheme,
    AppTokens tokens,
    TextTheme textTheme,
  ) => ThemeData(
    useMaterial3: true,
    fontFamily: AppTextStyles.qualifiedFamily,
    fontFamilyFallback: AppTextStyles.qualifiedFallback,
    colorScheme: scheme,
    brightness: scheme.brightness,
    textTheme: textTheme,
    extensions: [tokens],
    scaffoldBackgroundColor: tokens.background,
    canvasColor: tokens.background,
    dividerTheme: DividerThemeData(
      color: tokens.separator,
      thickness: .5,
      space: .5,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: tokens.accent),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.isClear ? 14 : 8),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.accent),
  );

  static ThemeData _clear(ColorScheme scheme, AppTokens t) {
    final text = AppTextStyles.textTheme(scheme);
    final textTheme = text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(t.controlRadius),
    );
    return _base(scheme, t, textTheme).copyWith(
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: scheme.brightness,
        primaryColor: t.accent,
        scaffoldBackgroundColor: t.background,
        barBackgroundColor: t.bar,
        textTheme: CupertinoTextThemeData(
          primaryColor: t.accent,
          textStyle: textTheme.bodyLarge?.copyWith(color: t.label),
          navTitleTextStyle: textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: t.label,
          ),
          // Myanmar stacks marks above and below: give titles room.
          navLargeTitleTextStyle: textTheme.headlineMedium?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
            height: 1.3,
            color: t.label,
          ),
          navActionTextStyle: textTheme.bodyLarge?.copyWith(
            fontSize: 17,
            color: t.accent,
          ),
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: t.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.label,
        iconTheme: IconThemeData(color: t.accent),
        actionsIconTheme: IconThemeData(color: t.accent),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: t.label,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.groupRadius),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.accent,
        textColor: t.label,
        tileColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.success : t.fill,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: controlShape,
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 50),
          shape: controlShape,
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: controlShape,
          foregroundColor: t.accent,
          side: BorderSide(color: t.separator),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: t.accent, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.fill,
        selectedColor: t.accent,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: t.label),
        secondaryLabelStyle: TextStyle(color: t.onAccent),
        checkmarkColor: t.onAccent,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: t.fill,
          selectedBackgroundColor: t.surface,
          selectedForegroundColor: t.label,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(t.sheetRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.accent,
        foregroundColor: t.onAccent,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: t.surfaceRaised,
        indicatorColor: t.accentSoft,
        selectedIconTheme: IconThemeData(color: t.accent),
      ),
    );
  }

  static ThemeData _material(ColorScheme scheme, AppTokens t) {
    final textTheme = AppTextStyles.textTheme(scheme);
    return _base(scheme, t, textTheme).copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: t.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.groupRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(t.sheetRadius),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.bar,
        indicatorColor: scheme.secondaryContainer,
        height: 80,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => textTheme.labelMedium?.copyWith(
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
    );
  }
}

import 'package:flutter/material.dart';

enum CalendarStudioAppearance { system, light, dark }

/// Semantic tokens copied from `calendar-studio-mockups.html`.
/// Canvas documents keep their own colours; these style the Studio chrome.
@immutable
class CalendarStudioTokens extends ThemeExtension<CalendarStudioTokens> {
  const CalendarStudioTokens({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.scrim,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.holiday,
    required this.gold,
    required this.ok,
    required this.warning,
    required this.error,
    required this.board,
    required this.boardInk,
    required this.board2,
  });

  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color scrim;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color holiday;
  final Color gold;
  final Color ok;
  final Color warning;
  final Color error;
  final Color board;
  final Color boardInk;
  final Color board2;

  static const light = CalendarStudioTokens(
    primary: Color(0xFF0E6B5C),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFFF4F7F5),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEDF2EF),
    surface3: Color(0xFFE1E8E4),
    scrim: Color(0x75101412),
    ink: Color(0xFF15201D),
    ink2: Color(0xFF465753),
    ink3: Color(0xFF74847F),
    line: Color(0xFFD5DEDA),
    holiday: Color(0xFFB8322A),
    gold: Color(0xFFB98A25),
    ok: Color(0xFF1E8A57),
    warning: Color(0xFFA96300),
    error: Color(0xFFC0352B),
    board: Color(0xFFDFE6E2),
    boardInk: Color(0xFF15201D),
    board2: Color(0xFFCDD7D2),
  );

  static const dark = CalendarStudioTokens(
    primary: Color(0xFF0E6B5C),
    onPrimary: Color(0xFF06201B),
    background: Color(0xFF0D1412),
    surface: Color(0xFF151E1C),
    surface2: Color(0xFF1C2725),
    surface3: Color(0xFF26332F),
    scrim: Color(0x99000000),
    ink: Color(0xFFE4EEEB),
    ink2: Color(0xFFA3B3AE),
    ink3: Color(0xFF7A8A85),
    line: Color(0xFF2A3835),
    holiday: Color(0xFFF2857B),
    gold: Color(0xFFE0B04E),
    ok: Color(0xFF5CC994),
    warning: Color(0xFFE6A445),
    error: Color(0xFFF28B82),
    board: Color(0xFF060B0A),
    boardInk: Color(0xFFE4EEEB),
    board2: Color(0xFF16201E),
  );

  Color get primaryContainer =>
      Color.alphaBlend(primary.withValues(alpha: .11), surface);
  Color get primaryContainerStrong =>
      Color.alphaBlend(primary.withValues(alpha: .20), surface);

  static CalendarStudioTokens of(BuildContext context) =>
      Theme.of(context).extension<CalendarStudioTokens>() ?? light;

  @override
  CalendarStudioTokens copyWith({
    Color? primary,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? scrim,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? line,
    Color? holiday,
    Color? gold,
    Color? ok,
    Color? warning,
    Color? error,
    Color? board,
    Color? boardInk,
    Color? board2,
  }) => CalendarStudioTokens(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surface2: surface2 ?? this.surface2,
    surface3: surface3 ?? this.surface3,
    scrim: scrim ?? this.scrim,
    ink: ink ?? this.ink,
    ink2: ink2 ?? this.ink2,
    ink3: ink3 ?? this.ink3,
    line: line ?? this.line,
    holiday: holiday ?? this.holiday,
    gold: gold ?? this.gold,
    ok: ok ?? this.ok,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    board: board ?? this.board,
    boardInk: boardInk ?? this.boardInk,
    board2: board2 ?? this.board2,
  );

  @override
  CalendarStudioTokens lerp(covariant CalendarStudioTokens? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return CalendarStudioTokens(
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surface2: mix(surface2, other.surface2),
      surface3: mix(surface3, other.surface3),
      scrim: mix(scrim, other.scrim),
      ink: mix(ink, other.ink),
      ink2: mix(ink2, other.ink2),
      ink3: mix(ink3, other.ink3),
      line: mix(line, other.line),
      holiday: mix(holiday, other.holiday),
      gold: mix(gold, other.gold),
      ok: mix(ok, other.ok),
      warning: mix(warning, other.warning),
      error: mix(error, other.error),
      board: mix(board, other.board),
      boardInk: mix(boardInk, other.boardInk),
      board2: mix(board2, other.board2),
    );
  }
}

/// Package-local design system translated from the HTML mockup.
abstract final class CalendarStudioTheme {
  // Compatibility aliases for callers that used the original light constants.
  static const primary = Color(0xFF0E6B5C);
  static const background = Color(0xFFF4F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEDF2EF);
  static const surface3 = Color(0xFFE1E8E4);
  static const ink = Color(0xFF15201D);
  static const ink2 = Color(0xFF465753);
  static const ink3 = Color(0xFF74847F);
  static const line = Color(0xFFD5DEDA);
  static const holiday = Color(0xFFB8322A);
  static const gold = Color(0xFFB98A25);
  static const warning = Color(0xFFA96300);
  static const error = Color(0xFFC0352B);

  static ThemeData get light =>
      fromTokens(CalendarStudioTokens.light, brightness: Brightness.light);
  static ThemeData get dark =>
      fromTokens(CalendarStudioTokens.dark, brightness: Brightness.dark);

  static ThemeData fromTokens(
    CalendarStudioTokens tokens, {
    Brightness brightness = Brightness.light,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.primary,
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      surface: tokens.surface,
      error: tokens.error,
    );
    const baseTextTheme = TextTheme(
      bodyLarge: TextStyle(fontSize: 15, height: 1.45),
      bodyMedium: TextStyle(fontSize: 13.5, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, height: 1.35),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      labelLarge: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [tokens],
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.surface,
      fontFamily: 'Noto Sans Myanmar',
      textTheme: baseTextTheme
          .apply(bodyColor: tokens.ink, displayColor: tokens.ink)
          .copyWith(
            bodySmall: baseTextTheme.bodySmall?.copyWith(color: tokens.ink3),
          ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: tokens.background,
        foregroundColor: tokens.ink,
        toolbarHeight: 56,
        titleTextStyle: TextStyle(
          color: tokens.ink,
          fontFamily: 'Noto Sans Myanmar',
          fontSize: 18.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: tokens.line),
        ),
      ),
      dividerColor: tokens.line,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.line),
          shape: const StadiumBorder(),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        modalBackgroundColor: tokens.surface,
        modalBarrierColor: tokens.scrim,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: tokens.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: tokens.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: tokens.primaryContainerStrong,
        side: BorderSide(color: tokens.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        labelStyle: TextStyle(fontSize: 12.5, color: tokens.ink2),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? tokens.primary
                : tokens.ink2,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? tokens.primaryContainerStrong
                : Colors.transparent,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.line)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),
    );
  }
}

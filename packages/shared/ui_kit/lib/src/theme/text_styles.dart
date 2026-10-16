import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App type: Inter for Latin text and numbers with Padauk for Myanmar,
/// both bundled (SIL Open Font License). Line heights leave room for
/// Myanmar marks stacked above and below.
class AppTextStyles {
  static const package = 'shared_ui_kit';
  static const family = 'Inter';
  static const myanmarFamily = 'Padauk';

  /// Fully qualified names, for code that builds TextStyles without
  /// `package:` (e.g. ThemeData.fontFamily).
  static const qualifiedFamily = 'packages/$package/$family';
  static const qualifiedFallback = ['packages/$package/$myanmarFamily'];

  static TextStyle _style(
    double size,
    FontWeight weight,
    double height,
    Color color, {
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: family,
    package: package,
    fontFamilyFallback: const [myanmarFamily],
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  static TextTheme textTheme(ColorScheme colorScheme) {
    final on = colorScheme.onSurface;
    final variant = colorScheme.onSurfaceVariant;
    return TextTheme(
      displayLarge: _style(57, FontWeight.w400, 1.15, on, letterSpacing: -.25),
      displayMedium: _style(45, FontWeight.w400, 1.2, on),
      displaySmall: _style(36, FontWeight.w400, 1.25, on),
      headlineLarge: _style(32, FontWeight.w600, 1.3, on, letterSpacing: -.3),
      headlineMedium: _style(28, FontWeight.w600, 1.3, on, letterSpacing: -.2),
      headlineSmall: _style(24, FontWeight.w600, 1.35, on),
      titleLarge: _style(22, FontWeight.w600, 1.35, on),
      titleMedium: _style(16, FontWeight.w600, 1.45, on),
      titleSmall: _style(14, FontWeight.w600, 1.45, on),
      bodyLarge: _style(16, FontWeight.w400, 1.55, on),
      bodyMedium: _style(14, FontWeight.w400, 1.55, on),
      bodySmall: _style(12, FontWeight.w400, 1.5, variant),
      labelLarge: _style(14, FontWeight.w600, 1.4, on),
      labelMedium: _style(12, FontWeight.w600, 1.4, on),
      labelSmall: _style(11, FontWeight.w500, 1.4, variant),
    );
  }

  /// Adds the bundled font licences to the app's licence page.
  static void registerLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final (name, path) in const [
        ('Inter', 'packages/$package/assets/fonts/inter/OFL.txt'),
        ('Padauk', 'packages/$package/assets/fonts/padauk/OFL.txt'),
      ]) {
        yield LicenseEntryWithLineBreaks([
          name,
        ], await rootBundle.loadString(path));
      }
    });
  }
}

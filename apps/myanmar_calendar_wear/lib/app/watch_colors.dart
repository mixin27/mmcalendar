import 'package:flutter/painting.dart';

/// The watch's colours: the phone app's dark design tokens (AppTokens), as
/// the Apple Watch app draws them, on the black a watch screen wants.
abstract final class WatchColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF1C1C1E);
  static const label = Color(0xFFF5F5F7);
  static const secondary = Color(0xFFA1A1A8);
  static const tertiary = Color(0xFF6C6C72);
  static const accent = Color(0xFF8AA6FF);
  static const accentSoft = Color(0x338AA6FF);
  static const holiday = Color(0xFFFF5A5F);
  static const holidaySoft = Color(0x29FF5A5F);
  static const sabbath = Color(0xFFFFB840);
  static const sabbathSoft = Color(0x29FFB840);
  static const moon = Color(0xFFFFC530);
  static const good = Color(0xFF34C77B);
  static const goodSoft = Color(0x2934C77B);
}

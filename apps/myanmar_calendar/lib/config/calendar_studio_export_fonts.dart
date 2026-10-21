import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/services.dart';

import 'calendar_studio_export_font_download.dart';

/// Fonts for Studio's vector PDF: static instances generated from Studio's
/// variable fonts (downloaded once, see `tool/build_export_fonts.py`), and
/// the app's own Noto Sans Myanmar from its assets.
const calendarStudioExportFonts = CalendarStudioExportFonts(
  download: downloadCalendarStudioExportFont,
  hostFont: _hostFont,
);

/// The Noto Sans Myanmar files the app declares, by weight.
const _notoSansMyanmar = {
  100: 'Thin',
  200: 'ExtraLight',
  300: 'Light',
  400: 'Regular',
  600: 'SemiBold',
  700: 'Bold',
  800: 'ExtraBold',
  900: 'Black',
};

Future<Uint8List?> _hostFont(String family, int weight, bool italic) async {
  if (family != 'Noto Sans Myanmar') return null;
  // The face Flutter picks: up to 500 looks lighter first (400 for 500).
  final weights = _notoSansMyanmar.keys.toList();
  final lighter = weights.where((w) => w <= weight);
  final heavier = weights.where((w) => w >= weight);
  final chosen = weight <= 500
      ? (lighter.isNotEmpty ? lighter.last : heavier.first)
      : (heavier.isNotEmpty ? heavier.first : lighter.last);
  final data = await rootBundle.load(
    'assets/fonts/google_fonts/NotoSansMyanmar-${_notoSansMyanmar[chosen]}.ttf',
  );
  return data.buffer.asUint8List();
}

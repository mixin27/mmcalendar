import 'dart:io';

import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  test('every catalog font is declared and its files and licence exist', () {
    final assets = RegExp(
      r'asset: (assets/fonts/\S+)',
    ).allMatches(pubspec).map((match) => match[1]!).toList();
    expect(assets, isNotEmpty);
    for (final path in assets) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    for (final font in CalendarStudioFontCatalog.fonts) {
      expect(pubspec, contains('- family: ${font.family}\n'), reason: font.id);
    }
    for (final dir in Directory(
      'assets/fonts',
    ).listSync().whereType<Directory>()) {
      expect(
        File('${dir.path}/OFL.txt').existsSync(),
        isTrue,
        reason: dir.path,
      );
    }
  });

  test('bundled families resolve to the package and fall back to Myanmar', () {
    expect(
      CalendarStudioFontCatalog.resolve('Fraunces'),
      'packages/calendar_studio/Fraunces',
    );
    expect(
      CalendarStudioFontCatalog.resolve('Noto Sans Myanmar'),
      'Noto Sans Myanmar',
    );

    final serif = CalendarStudioFontCatalog.style(
      family: 'Lora',
      weight: FontWeight.w700,
    );
    expect(
      serif.fontFamilyFallback!.first,
      CalendarStudioFontCatalog.serifMyanmar,
    );
    expect(serif.fontVariations, [const FontVariation('wght', 700)]);

    final sans = CalendarStudioFontCatalog.style(family: 'Sora');
    expect(
      sans.fontFamilyFallback!.first,
      CalendarStudioFontCatalog.sansMyanmar,
    );

    final staticFace = CalendarStudioFontCatalog.style(family: 'Spectral');
    expect(staticFace.fontVariations, isNull);
  });
}

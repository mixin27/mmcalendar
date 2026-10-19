// Generates every app icon from tool/app_icon_designs.dart: the iOS icon
// sets (the main one with iOS 18 dark and tinted versions), the Android
// adaptive, round, legacy and themed layers, the Settings previews, the
// Play Store and web icons.
//
// Run from apps/myanmar_calendar: `flutter test tool/app_icons_test.dart`.
//
// Icon ids are stable: they name the Android activity-alias and the iOS
// alternate icon that someone may have chosen. Older ids keep their alias
// and get new artwork (forest is now Jade, and so on), so an update never
// removes the launcher entry in use.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_icon_designs.dart';
import 'png.dart';

/// One choice in Settings › App icon.
class _Icon {
  const _Icon(this.id, this.design);

  /// The id the app stores and the platforms map to an alias or icon set.
  final String id;

  /// A palette name, 'pagoda' or 'classic'.
  final String design;

  bool get isDefault => id == 'default';

  /// Android resource base name.
  String get res => isDefault ? 'ic_launcher' : 'ic_launcher_$id';

  /// iOS icon set name.
  String get iosSet => isDefault ? 'AppIcon' : 'AppIcon${_pascal(id)}';

  /// The Settings preview.
  String get preview => isDefault
      ? 'assets/branding/app_icon_1024.png'
      : 'assets/branding/app_icon_${id}_1024.png';
}

String _pascal(String id) =>
    id.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join();

/// In Settings order.
const icons = [
  _Icon('default', 'night'),
  _Icon('dawn', 'dawn'),
  _Icon('forest', 'jade'),
  _Icon('traditional_myanmar', 'lacquer'),
  _Icon('minimal_flat', 'paper'),
  _Icon('premium_dark', 'midnight'),
  _Icon('thingyan', 'thingyan'),
  _Icon('moon', 'dusk'),
  _Icon('pagoda', 'pagoda'),
  _Icon('classic', 'classic'),
];

const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

void main() {
  final app = Directory.current.path;
  late ui.Image classic;

  setUpAll(() async {
    final bytes = await File(
      '$app/assets/branding/app_icon_classic_1024.png',
    ).readAsBytes();
    classic = (await (await ui.instantiateImageCodec(
      bytes,
    )).getNextFrame()).image;
  });

  /// The 1024 artwork of [icon] in [layer] and [appearance].
  Future<ui.Picture> art(
    _Icon icon, {
    IconLayer layer = IconLayer.full,
    IconAppearance appearance = IconAppearance.light,
  }) async {
    if (icon.design == 'classic') {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      if (layer != IconLayer.foreground) {
        canvas.drawImageRect(
          classic,
          Rect.fromLTWH(0, 0, classic.width * 1.0, classic.height * 1.0),
          const Rect.fromLTWH(0, 0, 1024, 1024),
          Paint()..filterQuality = FilterQuality.high,
        );
      }
      return recorder.endRecording();
    }
    final svg = icon.design == 'pagoda'
        ? pagoda(layer: layer)
        : moonPage(
            palettes[icon.design]!,
            layer: layer,
            appearance: appearance,
          );
    return (await vg.loadPicture(SvgStringLoader(svg), null)).picture;
  }

  /// [picture] (1024 square) drawn at [size], clipped to [clip].
  ui.Picture scaled(ui.Picture picture, double size, {Path? clip}) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (clip != null) canvas.clipPath(clip);
    canvas.scale(size / 1024);
    canvas.drawPicture(picture);
    return recorder.endRecording();
  }

  Future<List<int>> rgba(ui.Picture picture, int size) async {
    final image = await picture.toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> write(String path, List<int> bytes) async {
    final file = File('$app/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  testWidgets('iOS icon sets', (tester) async {
    await tester.runAsync(() async {
      final catalog = '$app/ios/Runner/Assets.xcassets';
      for (final icon in icons) {
        final dir = Directory('$catalog/${icon.iosSet}.appiconset');
        if (dir.existsSync()) dir.deleteSync(recursive: true);
        dir.createSync(recursive: true);
        // App Store icons must be opaque.
        Future<void> png(String name, IconAppearance appearance) async =>
            File('${dir.path}/$name').writeAsBytes(
              await encodeRgbPng(
                await art(icon, appearance: appearance),
                const Size(1024, 1024),
              ),
            );
        final images = <Map<String, Object>>[
          {
            'filename': 'icon.png',
            'idiom': 'universal',
            'platform': 'ios',
            'size': '1024x1024',
          },
        ];
        await png('icon.png', IconAppearance.light);
        // iOS 18 dark and tinted, for the main icon.
        if (icon.isDefault) {
          for (final (name, appearance) in [
            ('dark', IconAppearance.dark),
            ('tinted', IconAppearance.tinted),
          ]) {
            await png('icon_$name.png', appearance);
            images.add({
              'appearances': [
                {'appearance': 'luminosity', 'value': name},
              ],
              'filename': 'icon_$name.png',
              'idiom': 'universal',
              'platform': 'ios',
              'size': '1024x1024',
            });
          }
        }
        File('${dir.path}/Contents.json').writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert({
            'images': images,
            'info': {'author': 'xcode', 'version': 1},
          })}\n',
        );
      }
    });
  });

  testWidgets('Android launcher icons', (tester) async {
    await tester.runAsync(() async {
      final res = '$app/android/app/src/main/res';
      // Older icon files: webp bitmaps and inset foregrounds.
      for (final dir in Directory(res).listSync().whereType<Directory>()) {
        final name = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
        if (!name.startsWith('mipmap') && name != 'drawable') continue;
        for (final file in dir.listSync().whereType<File>()) {
          final base = file.uri.pathSegments.last;
          if (base.startsWith('ic_launcher')) file.deleteSync();
        }
      }

      final mono = (await vg.loadPicture(
        SvgStringLoader(monochrome()),
        null,
      )).picture;
      for (final MapEntry(key: dpi, value: scale) in _densities.entries) {
        final legacy = (48 * scale).round().toDouble();
        final adaptive = (108 * scale).round().toDouble();
        final dir = 'android/app/src/main/res/mipmap-$dpi';
        await write(
          '$dir/ic_launcher_monochrome.png',
          await rgba(scaled(mono, adaptive), adaptive.round()),
        );
        for (final icon in icons) {
          final full = await art(icon);
          final square = Path()
            ..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(0, 0, legacy, legacy),
                Radius.circular(legacy * .18),
              ),
            );
          final round = Path()..addOval(Rect.fromLTWH(0, 0, legacy, legacy));
          await write(
            '$dir/${icon.res}.png',
            await rgba(scaled(full, legacy, clip: square), legacy.round()),
          );
          await write(
            '$dir/${icon.res}_round.png',
            await rgba(scaled(full, legacy, clip: round), legacy.round()),
          );
          await write(
            '$dir/${icon.res}_background.png',
            await rgba(
              scaled(await art(icon, layer: IconLayer.background), adaptive),
              adaptive.round(),
            ),
          );
          await write(
            '$dir/${icon.res}_foreground.png',
            await rgba(
              scaled(await art(icon, layer: IconLayer.foreground), adaptive),
              adaptive.round(),
            ),
          );
        }
      }

      String adaptiveXml(_Icon icon) =>
          '<?xml version="1.0" encoding="utf-8"?>\n'
          '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
          '    <background android:drawable="@mipmap/${icon.res}_background"/>\n'
          '    <foreground android:drawable="@mipmap/${icon.res}_foreground"/>\n'
          '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
          '</adaptive-icon>\n';
      for (final icon in icons) {
        for (final suffix in ['', '_round']) {
          await write(
            'android/app/src/main/res/mipmap-anydpi-v26/${icon.res}$suffix.xml',
            adaptiveXml(icon).codeUnits,
          );
        }
      }

      // Play Store listing icon.
      await write(
        'android/app/src/main/ic_launcher-playstore.png',
        await encodeRgbPng(
          scaled(await art(icons.first), 512),
          const Size(512, 512),
        ),
      );
    });
  });

  testWidgets('Settings previews and web icons', (tester) async {
    await tester.runAsync(() async {
      for (final icon in icons.where((i) => i.design != 'classic')) {
        await write(
          icon.preview,
          await encodeRgbPng(await art(icon), const Size(1024, 1024)),
        );
      }
      final main = await art(icons.first);
      for (final (path, size) in [
        ('web/icons/android-chrome-192x192.png', 192.0),
        ('web/icons/android-chrome-512x512.png', 512.0),
        ('web/icons/apple-touch-icon.png', 180.0),
        ('web/icons/favicon-32x32.png', 32.0),
        ('web/icons/favicon-16x16.png', 16.0),
        ('web/favicon.png', 32.0),
      ]) {
        if (!File('$app/$path').existsSync()) continue;
        await write(
          path,
          await encodeRgbPng(scaled(main, size), Size(size, size)),
        );
      }
    });
  });
}

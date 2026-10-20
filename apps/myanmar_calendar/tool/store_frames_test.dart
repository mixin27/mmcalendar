// Store screenshots: frames the raw captures from
// `scripts/capture_store_screens.sh` with a Myanmar caption on the brand's
// night sky, at the exact sizes the App Store and Google Play ask for.
//
// Run from apps/myanmar_calendar: `flutter test tool/store_frames_test.dart`.
// Writes to <repo>/store/.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'png.dart';

/// The brand: the app icon's night sky, moon and gold stars.
const _skyTop = Color(0xFF14203D);
const _skyBottom = Color(0xFF2B5598);
const _moon = Color(0xFFEEF3FC);
const _gold = Color(0xFFF4C562);
const _subtle = Color(0xFFB9C9EA);

/// Headline and line under it, per screen, in Myanmar.
const _captions = {
  '01_home': (
    'မြန်မာ နှင့် အင်္ဂလိပ် ပြက္ခဒိန်',
    'လရက်၊ လဝန်း၊ ရုံးပိတ်ရက်နှင့် ပွဲများ တစ်နေရာတည်းတွင်',
  ),
  '02_day_details': (
    'နေ့တိုင်း၏ အသေးစိတ်',
    'ဥပုသ်၊ ရက်ရာဇာ၊ မဟာဘုတ်၊ နဂါးခေါင်း',
  ),
  '03_holidays': ('ရုံးပိတ်ရက်များ', 'ရှာဖွေ၊ စစ်ထုတ်ပြီး သတိပေးချက် ထားပါ'),
  '04_myanmar_month': ('မြန်မာလအလိုက် ကြည့်ရှု', 'လဆန်း၊ လပြည့်၊ လဆုတ်၊ လကွယ်'),
  '05_timetable': (
    'အတန်းချိန်ဇယား တစ်ခါတည်း',
    'အပတ်စဉ် နေ့များ၊ ရက်များစွာနှင့် သတိပေးချက်',
  ),
  '06_studio': (
    'ကိုယ်ပိုင် ပြက္ခဒိန် ဒီဇိုင်း',
    'Calendar Studio ဖြင့် ဖန်တီးပြီး PDF ထုတ်ပါ',
  ),
  '07_grid_styles': (
    'ပြက္ခဒိန်ပုံစံ ၂၂ မျိုး',
    'အရောင်အသွေး ၁၃ မျိုးဖြင့် စိတ်ကြိုက်ပြင်ဆင်',
  ),
  '08_converter': (
    'ရက်စွဲ ပြောင်းလဲခြင်း',
    'မြန်မာ ↔ အင်္ဂလိပ်၊ ရက်ကွာခြားချက် တွက်ချက်',
  ),
};

/// One store set: where its captures come from and the canvas it needs.
class _Target {
  const _Target(this.source, this.output, this.size);
  final String source;
  final String output;
  final Size size;
}

const _targets = [
  _Target('iphone', 'app_store/iphone_6_9', Size(1320, 2868)),
  _Target('ipad', 'app_store/ipad_13', Size(2064, 2752)),
  // Play caps phones at 2:1 and wants 9:16 or 16:9 for tablets; the app is
  // portrait-only, so both are 9:16.
  _Target('android_phone', 'play_store/phone', Size(1080, 1920)),
  _Target('android_tablet', 'play_store/tablet_10', Size(1440, 2560)),
];

void main() {
  final app = Directory.current.path;
  final repo = Directory('$app/../..').absolute.path;

  setUpAll(() async {
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final file in files) {
        final bytes = await File(
          '$app/assets/fonts/google_fonts/$file',
        ).readAsBytes();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    }

    await load('Myanmar', [
      'NotoSansMyanmar-Bold.ttf',
      'NotoSansMyanmar-Regular.ttf',
    ]);
    // Inter for symbols Noto Sans Myanmar lacks, such as the arrow.
    final inter = await File(
      '$app/../../packages/shared/ui_kit/assets/fonts/inter/Inter-Variable.ttf',
    ).readAsBytes();
    await (FontLoader(
      'FrameLatin',
    )..addFont(Future.value(ByteData.sublistView(inter)))).load();
  });

  for (final target in _targets) {
    testWidgets('frames ${target.output}', (tester) async {
      final source = Directory('$app/build/store_raw/${target.source}');
      if (!source.existsSync()) {
        markTestSkipped('No captures in ${source.path}');
        return;
      }
      final shots =
          source
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.png'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      final out = Directory('$repo/store/${target.output}')
        ..createSync(recursive: true);
      for (final shot in shots) {
        final name = shot.uri.pathSegments.last.replaceAll('.png', '');
        final caption = _captions[name];
        if (caption == null) continue;
        final bytes = await tester.runAsync(() async {
          final screen = await _decode(await shot.readAsBytes());
          return _frame(target.size, screen, caption.$1, caption.$2);
        });
        File('${out.path}/$name.png').writeAsBytesSync(bytes!);
      }
    });
  }

  testWidgets('feature graphic', (tester) async {
    final shot = File('$app/build/store_raw/android_phone/01_home.png');
    final fallback = File('$app/build/store_raw/iphone/01_home.png');
    final source = shot.existsSync() ? shot : fallback;
    if (!source.existsSync()) {
      markTestSkipped('No home capture yet');
      return;
    }
    final bytes = await tester.runAsync(() async {
      final screen = await _decode(await source.readAsBytes());
      return _featureGraphic(screen);
    });
    File('$repo/store/play_store/feature_graphic.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  });

  // The flutter_mmcalendar portfolio page: a landscape graphic from the
  // package's own screenshots, in its three styles.
  testWidgets('flutter_mmcalendar feature graphic', (tester) async {
    final shots = Directory('$repo/../flutter-mmcalendar/screenshots');
    if (!shots.existsSync()) {
      markTestSkipped('No flutter-mmcalendar checkout next to this repo');
      return;
    }
    final bytes = await tester.runAsync(() async {
      Future<ui.Image> shot(String name) async =>
          _decode(await File('${shots.path}/$name.jpg').readAsBytes());
      return _packageGraphic(
        await shot('calendar_material_dark'),
        await shot('calendar_glass_light'),
        await shot('tools_cupertino_light'),
      );
    });
    File(
        '$repo/docs/portfolio/images/projects/flutter-mmcalendar/feature-graphic.png',
      )
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  });
}

/// 1600×800: flutter_mmcalendar's name and pitch beside its Material,
/// Liquid Glass and Cupertino screens, on the glass demo's dusk sky.
Future<List<int>> _packageGraphic(
  ui.Image material,
  ui.Image glass,
  ui.Image cupertino,
) {
  const size = Size(1600, 800);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6F7FE6), Color(0xFFA996E0), Color(0xFFF0B07A)],
        stops: [0, .55, 1],
      ).createShader(rect),
  );
  canvas.drawCircle(
    const Offset(1380, 140),
    260,
    Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFFD45E).withValues(alpha: .55),
              const Color(0xFFFFD45E).withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: const Offset(1380, 140), radius: 260),
          ),
  );

  TextPainter latin(String text, double size, Color color, FontWeight weight) =>
      TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'FrameLatin',
            fontFamilyFallback: const ['Myanmar'],
            fontSize: size,
            height: 1.25,
            fontWeight: weight,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 640);

  const ink = Color(0xFF1C1F3A);
  final title = latin('flutter_mmcalendar', 64, ink, FontWeight.w800);
  final pitch = latin(
    'Myanmar calendar widgets for Flutter',
    32,
    ink.withValues(alpha: .78),
    FontWeight.w500,
  );
  final styles = latin(
    'Material 3  ·  Cupertino  ·  Liquid Glass',
    26,
    ink.withValues(alpha: .7),
    FontWeight.w600,
  );
  final tag = latin(
    'ပြက္ခဒိန် ဝစ်ဂျက်များ  ·  v4',
    26,
    ink.withValues(alpha: .6),
    FontWeight.w500,
  );
  var y = 250.0;
  for (final (painter, gap) in [
    (title, 18.0),
    (pitch, 40.0),
    (styles, 16.0),
    (tag, 0.0),
  ]) {
    painter.paint(canvas, Offset(88, y));
    y += painter.height + gap;
  }

  // Back two phones, then Liquid Glass in front.
  _paintDevice(canvas, material, const Rect.fromLTRB(800, 150, 1080, 760));
  _paintDevice(canvas, cupertino, const Rect.fromLTRB(1260, 150, 1540, 760));
  _paintDevice(canvas, glass, const Rect.fromLTRB(1010, 60, 1340, 780));
  return encodeRgbPng(recorder.endRecording(), size);
}

Future<ui.Image> _decode(List<int> bytes) async {
  final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
  return (await codec.getNextFrame()).image;
}

/// The night sky with a soft moon glow and a few gold stars.
void _paintSky(Canvas canvas, Size size, {Offset? glow}) {
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_skyTop, _skyBottom],
      ).createShader(rect),
  );
  final center = glow ?? Offset(size.width * .82, size.height * .06);
  final radius = size.shortestSide * .45;
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        colors: [_moon.withValues(alpha: .18), _moon.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius)),
  );
  // Stars at fixed places, so every frame in a set matches.
  final random = math.Random(27);
  final unit = size.shortestSide / 100;
  for (var i = 0; i < 14; i++) {
    // In the side margins only, clear of the caption.
    final side = random.nextBool();
    final at = Offset(
      (side ? .91 + random.nextDouble() * .08 : random.nextDouble() * .08) *
          size.width,
      random.nextDouble() * size.height * .3,
    );
    final r = unit * (.25 + random.nextDouble() * .45);
    final gold = i % 4 == 0;
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..color = (gold ? _gold : _moon).withValues(alpha: gold ? .9 : .55),
    );
  }
}

TextPainter _text(
  String text,
  double size,
  Color color,
  FontWeight weight,
  double maxWidth, {
  TextAlign align = TextAlign.center,
}) => TextPainter(
  text: TextSpan(
    text: text,
    style: TextStyle(
      fontFamily: 'Myanmar',
      fontFamilyFallback: const ['FrameLatin'],
      fontSize: size,
      height: 1.55,
      fontWeight: weight,
      color: color,
    ),
  ),
  textAlign: align,
  textDirection: TextDirection.ltr,
)..layout(maxWidth: maxWidth);

/// [screen] in a rounded device outline, scaled to fit [box].
void _paintDevice(Canvas canvas, ui.Image screen, Rect box) {
  final ratio = screen.width / screen.height;
  var width = box.width;
  var height = width / ratio;
  if (height > box.height) {
    height = box.height;
    width = height * ratio;
  }
  final screenRect = Rect.fromCenter(
    center: box.center,
    width: width,
    height: height,
  );
  final radius = width * (ratio < 1 ? .085 : .045);
  final bezel = width * .022;
  final body = RRect.fromRectAndRadius(
    screenRect.inflate(bezel),
    Radius.circular(radius + bezel),
  );
  canvas.drawShadow(Path()..addRRect(body), Colors.black, width * .03, true);
  canvas.drawRRect(body, Paint()..color = const Color(0xFF0B1022));
  canvas.drawRRect(
    body,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bezel * .18
      ..color = _subtle.withValues(alpha: .35),
  );
  canvas.save();
  canvas.clipRRect(
    RRect.fromRectAndRadius(screenRect, Radius.circular(radius)),
  );
  canvas.drawImageRect(
    screen,
    Rect.fromLTWH(0, 0, screen.width * 1.0, screen.height * 1.0),
    screenRect,
    Paint()..filterQuality = FilterQuality.high,
  );
  canvas.restore();
}

Future<List<int>> _frame(
  Size size,
  ui.Image screen,
  String headline,
  String line,
) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _paintSky(canvas, size);
  final landscape = size.width > size.height;
  final unit = size.shortestSide / 100;

  if (landscape) {
    // Caption on the left, the device on the right.
    final textWidth = size.width * .32;
    final title = _text(
      headline,
      unit * 6.2,
      Colors.white,
      FontWeight.w700,
      textWidth,
      align: TextAlign.left,
    );
    final sub = _text(
      line,
      unit * 3.3,
      _subtle,
      FontWeight.w400,
      textWidth,
      align: TextAlign.left,
    );
    final top = (size.height - title.height - sub.height - unit * 2) / 2;
    title.paint(canvas, Offset(size.width * .06, top));
    sub.paint(canvas, Offset(size.width * .06, top + title.height + unit * 2));
    _paintDevice(
      canvas,
      screen,
      Rect.fromLTRB(
        size.width * .42,
        size.height * .08,
        size.width * .96,
        size.height * .92,
      ),
    );
  } else {
    final textWidth = size.width * .86;
    final title = _text(
      headline,
      unit * 7.4,
      Colors.white,
      FontWeight.w700,
      textWidth,
    );
    final sub = _text(line, unit * 3.9, _subtle, FontWeight.w400, textWidth);
    final top = size.height * .045;
    title.paint(canvas, Offset((size.width - title.width) / 2, top));
    final subTop = top + title.height + unit;
    sub.paint(canvas, Offset((size.width - sub.width) / 2, subTop));
    final deviceTop = subTop + sub.height + unit * 5;
    _paintDevice(
      canvas,
      screen,
      Rect.fromLTRB(
        size.width * .1,
        deviceTop,
        size.width * .9,
        size.height - unit * 3,
      ),
    );
  }
  return encodeRgbPng(recorder.endRecording(), size);
}

/// Play's 1024×500 feature graphic: the name and pitch beside the app.
Future<List<int>> _featureGraphic(ui.Image screen) {
  const size = Size(1024, 500);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _paintSky(canvas, size, glow: const Offset(860, 120));
  final title = _text(
    'မြန်မာ ပြက္ခဒိန်',
    58,
    Colors.white,
    FontWeight.w700,
    560,
    align: TextAlign.left,
  );
  final sub = _text(
    'လရက်၊ ဗေဒင်၊ ရုံးပိတ်ရက်၊ ပွဲများနှင့်\nကိုယ်ပိုင် ပြက္ခဒိန် ဒီဇိုင်း',
    26,
    _subtle,
    FontWeight.w400,
    560,
    align: TextAlign.left,
  );
  final top = (size.height - title.height - sub.height - 12) / 2;
  title.paint(canvas, Offset(64, top));
  sub.paint(canvas, Offset(64, top + title.height + 12));
  // The moon, as on the icon.
  canvas.drawCircle(
    const Offset(560, 92),
    10,
    Paint()..color = _gold.withValues(alpha: .9),
  );
  _paintDevice(canvas, screen, const Rect.fromLTRB(660, 36, 960, 540));
  return encodeRgbPng(recorder.endRecording(), size);
}

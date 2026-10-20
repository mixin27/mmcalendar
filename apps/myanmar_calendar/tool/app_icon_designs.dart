// The app icons as SVG, on a 1024 × 1024 canvas (docs/design/app-icons.html).
//
// Moon page: a tear-off calendar page whose day is the moon, in eight
// palettes from the grid themes. Pagoda: a stupa under the full moon.
// Classic (today's icon) is a bitmap, not drawn here.
import 'dart:math' as math;

/// One Moon page palette.
class IconPalette {
  const IconPalette({
    required this.bg,
    required this.page,
    required this.band,
    required this.moon,
    required this.shade,
    required this.ink,
    required this.star,
  });

  /// Background gradient, top left to bottom right.
  final (String, String) bg;
  final String page;
  final String band;
  final String moon;

  /// The moon's unlit part.
  final String shade;

  /// The binder rings.
  final String ink;
  final String star;
}

const palettes = <String, IconPalette>{
  'night': IconPalette(
    bg: ('#14203D', '#2B5598'),
    page: '#EEF3FC',
    band: '#F4C562',
    moon: '#F4C562',
    shade: '#AFC0E4',
    ink: '#14203D',
    star: '#F4C562',
  ),
  'dawn': IconPalette(
    bg: ('#F8C98E', '#E5735C'),
    page: '#FFF6EC',
    band: '#7A2E3A',
    moon: '#E5735C',
    shade: '#F3D7C4',
    ink: '#5A2230',
    star: '#FFF6EC',
  ),
  'jade': IconPalette(
    bg: ('#0B4D43', '#1F8C72'),
    page: '#EFF7F2',
    band: '#D9B44A',
    moon: '#D9B44A',
    shade: '#B9D8CA',
    ink: '#0B4D43',
    star: '#F2E3A6',
  ),
  'lacquer': IconPalette(
    bg: ('#5E0F0C', '#B12B1C'),
    page: '#F7E9D3',
    band: '#1C1110',
    moon: '#E2A93B',
    shade: '#E7CFAE',
    ink: '#3B0B08',
    star: '#E2A93B',
  ),
  'paper': IconPalette(
    bg: ('#FBF7EF', '#EFE6D4'),
    page: '#FFFFFF',
    band: '#2F5BEA',
    moon: '#2F5BEA',
    shade: '#D7DEF2',
    ink: '#1F2A44',
    star: '#2F5BEA',
  ),
  'midnight': IconPalette(
    bg: ('#04060D', '#161D33'),
    page: '#1C2338',
    band: '#F4C562',
    moon: '#F4C562',
    shade: '#39425E',
    ink: '#EEF3FC',
    star: '#F4C562',
  ),
  'thingyan': IconPalette(
    bg: ('#25B6CF', '#1666BD'),
    page: '#F4FBFF',
    band: '#F7C628',
    moon: '#F7C628',
    shade: '#C3E3F1',
    ink: '#0E3F7A',
    star: '#F7C628',
  ),
  'dusk': IconPalette(
    bg: ('#6F7FE6', '#F0B07A'),
    page: '#FBF6FF',
    band: '#3A2F7A',
    moon: '#F0B07A',
    shade: '#DCD3F2',
    ink: '#2A2465',
    star: '#FFFFFF',
  ),
};

/// Which layers of an icon to draw.
enum IconLayer {
  /// Everything: the square icon.
  full,

  /// Android adaptive background: the sky only.
  background,

  /// Android adaptive foreground: the page and moon on transparent.
  foreground,
}

/// Android shows the middle 72 of an adaptive icon's 108 dp and masks
/// that further, so its layers draw the artwork this much smaller.
const androidScale = .78;

/// Wraps [body] in a scale of [androidScale] about the centre.
String _androidInset(String body) =>
    '<g transform="translate(512 512) scale($androidScale) '
    'translate(-512 -512)">$body</g>';

/// How the iOS 18 home screen shows the icon.
enum IconAppearance { light, dark, tinted }

String _svg(String body, {String defs = ''}) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">'
    '<defs>$defs</defs>$body</svg>';

String _gradient(String id, (String, String) colors, {bool vertical = false}) =>
    '<linearGradient id="$id" x1="0" y1="0" x2="${vertical ? 0 : 1}" '
    'y2="1"><stop offset="0" stop-color="${colors.$1}"/>'
    '<stop offset="1" stop-color="${colors.$2}"/></linearGradient>';

/// A waxing moon at ([cx], [cy]): [shade] disc, lit from the right.
/// [phase] 0 is new, .5 half, 1 full.
String _moon(
  double cx,
  double cy,
  double r,
  String lit,
  String shade,
  double phase,
) {
  final k = math.cos(phase * math.pi) * r;
  final sweep = k > 0 ? 0 : 1;
  return '<circle cx="$cx" cy="$cy" r="$r" fill="$shade"/>'
      '<path d="M$cx ${cy - r} A$r $r 0 0 1 $cx ${cy + r} '
      'A${k.abs()} $r 0 0 $sweep $cx ${cy - r}Z" fill="$lit"/>';
}

String _stars(String color, List<(double, double, double)> stars) => [
  for (final (x, y, s) in stars)
    '<path d="M$x ${y - s}L${x + s * .28} ${y - s * .28}L${x + s} $y'
        'L${x + s * .28} ${y + s * .28}L$x ${y + s}L${x - s * .28} '
        '${y + s * .28}L${x - s} ${y}L${x - s * .28} ${y - s * .28}Z" '
        'fill="$color"/>',
].join();

/// The Moon page icon in [p].
String moonPage(
  IconPalette p, {
  IconLayer layer = IconLayer.full,
  IconAppearance appearance = IconAppearance.light,
}) {
  final dark = appearance == IconAppearance.dark;
  final tinted = appearance == IconAppearance.tinted;
  final sky = dark
      ? '<rect width="1024" height="1024" fill="#000000"/>'
      : tinted
      ? '<rect width="1024" height="1024" fill="#000000"/>'
      : '<rect width="1024" height="1024" fill="url(#sky)"/>'
            '${_stars(p.star, layer == IconLayer.full ? [(220, 210, 26), (820, 250, 18), (790, 820, 22)] : [(290, 290, 22), (760, 300, 15), (745, 745, 18)])}';
  final page = dark
      ? '#1A2032'
      : tinted
      ? '#3A3A3A'
      : p.page;
  final band = dark
      ? p.moon
      : tinted
      ? '#D0D0D0'
      : p.band;
  final lit = tinted ? '#FFFFFF' : p.moon;
  final shade = dark
      ? '#3A4360'
      : tinted
      ? '#6A6A6A'
      : p.shade;
  final ring = dark
      ? '#2A3149'
      : tinted
      ? '#8A8A8A'
      : p.ink;
  final glyph =
      '<rect x="232" y="262" width="560" height="560" rx="104" fill="$page"/>'
      '<path d="M232 366a104 104 0 0 1 104-104h352a104 104 0 0 1 104 104'
      'v40H232z" fill="$band"/>'
      '<rect x="352" y="214" width="44" height="104" rx="22" fill="$ring"/>'
      '<rect x="628" y="214" width="44" height="104" rx="22" fill="$ring"/>'
      '${_moon(512, 610, 150, lit, shade, .38)}';
  final body = switch (layer) {
    IconLayer.full => sky + glyph,
    IconLayer.background => sky,
    IconLayer.foreground => _androidInset(glyph),
  };
  return _svg(body, defs: _gradient('sky', p.bg));
}

/// Android's themed (monochrome) layer: the page and moon as one shape.
String monochrome() => _svg(
  _androidInset(
    '<g fill="#FFFFFF">'
    '<path fill-rule="evenodd" d="M336 262h352a104 104 0 0 1 104 104v352'
    'a104 104 0 0 1-104 104H336a104 104 0 0 1-104-104V366a104 104 0 0 1 '
    '104-104zM288 430v288a48 48 0 0 0 48 48h352a48 48 0 0 0 48-48V430z"/>'
    '<rect x="352" y="214" width="44" height="104" rx="22"/>'
    '<rect x="628" y="214" width="44" height="104" rx="22"/>'
    '<circle cx="512" cy="598" r="120"/></g>',
  ),
);

/// A stupa under the full moon, on the Night sky.
String pagoda({IconLayer layer = IconLayer.full}) {
  final p = palettes['night']!;
  if (layer == IconLayer.foreground) return _svg('');
  final scene =
      '<circle cx="640" cy="372" r="190" fill="${p.moon}"/>'
      '${_stars(p.star, [(230, 230, 22), (300, 380, 14), (860, 620, 16)])}'
      '<path d="M512 210 L524 330 C590 360 620 420 630 520 L660 520 L660 560 '
      'L700 560 L700 610 L748 610 L748 670 L276 670 L276 610 L324 610 '
      'L324 560 L364 560 L364 520 L394 520 C404 420 434 360 500 330 Z" '
      'fill="${p.ink}"/>'
      '<path d="M0 700 C220 650 380 690 512 672 C660 652 820 680 1024 650 '
      'V1024 H0Z" fill="${p.ink}"/>';
  return _svg(
    '<rect width="1024" height="1024" fill="url(#sky)"/>'
    '${layer == IconLayer.background ? _androidInset(scene) : scene}',
    defs: _gradient('sky', p.bg, vertical: true),
  );
}

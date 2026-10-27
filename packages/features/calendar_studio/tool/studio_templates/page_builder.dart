import 'dart:math' as math;

/// Page shapes the pack uses, with the canvas Studio stores (millimetres for
/// paper) and the design size block sizes are written in.
enum StudioFormat {
  square(600, 600, 600, 600, 'Social · square'),
  a4Portrait(210, 297, 595, 842, 'Wall · A4 portrait'),
  a4Landscape(297, 210, 842, 595, 'Desk · A4 landscape');

  const StudioFormat(
    this.canvasWidth,
    this.canvasHeight,
    this.designWidth,
    this.designHeight,
    this.category,
  );
  final double canvasWidth;
  final double canvasHeight;
  final double designWidth;
  final double designHeight;
  final String category;

  /// Render size for previews, long edge [long] pixels.
  (int, int) pixels(int long) => designWidth >= designHeight
      ? (long, (long * designHeight / designWidth).round())
      : ((long * designWidth / designHeight).round(), long);
}

/// A design's colours, by the roles Studio's re-theme understands.
class StudioPalette {
  const StudioPalette({
    required this.paper,
    required this.primary,
    required this.accent,
    required this.ink,
    required this.muted,
    required this.line,
    required this.holiday,
    required this.sabbath,
  });
  final int paper;
  final int primary;
  final int accent;
  final int ink;
  final int muted;
  final int line;
  final int holiday;
  final int sabbath;

  /// Swatches for the template gallery card.
  List<int> get swatches => [paper, primary, accent, ink, holiday];
}

const white = 0xFFFFFFFF;

/// Builds one page as Studio's document JSON: block bounds are fractions of
/// the page, sizes are in design units, rotation is given in degrees.
class PageBuilder {
  PageBuilder(this.palette);

  final StudioPalette palette;
  final blocks = <Map<String, Object?>>[];

  void block(
    String type,
    String name,
    List<double> bounds, {
    double rotation = 0,
    int? zIndex,
    Map<String, Object?> style = const {},
    Map<String, Object?> content = const {},
  }) => blocks.add({
    'id': '$type-${blocks.length}',
    'type': type,
    'name': name,
    'bounds': {
      'left': bounds[0],
      'top': bounds[1],
      'width': bounds[2],
      'height': bounds[3],
    },
    'rotation': rotation * math.pi / 180,
    'zIndex': zIndex ?? blocks.length,
    'visible': true,
    'locked': false,
    'style': style,
    'content': content,
  });

  void text(
    String name,
    List<double> bounds,
    String text, {
    String family = 'Noto Sans Myanmar',
    double size = 16,
    int weight = 500,
    bool italic = false,
    int? color,
    String align = 'left',
    double letterSpacing = 0,
    double rotation = 0,
    String? subtitle,
    Map<String, Object?> content = const {},
  }) => block(
    'text',
    name,
    bounds,
    rotation: rotation,
    style: {
      'color': color ?? palette.ink,
      'fontSize': size,
      'fontFamily': family,
      'fontWeight': weight,
      'align': align,
      'vAlign': 'center',
      'italic': italic,
      'subtitleItalic': true,
      'subtitleColor': palette.muted,
      'subtitleScale': .42,
      'letterSpacing': letterSpacing,
      'lineHeight': 1.3,
    },
    content: {'text': text, 'subtitle': ?subtitle, ...content},
  );

  /// The month title: Studio fills in the month for each page and year
  /// (Myanmar with the English name under it, in "both" languages).
  void monthTitle(
    List<double> bounds, {
    String family = 'Cormorant Garamond',
    double size = 40,
    int weight = 600,
    int? color,
    String align = 'left',
  }) => text(
    'Month title',
    bounds,
    'Month',
    family: family,
    size: size,
    weight: weight,
    color: color ?? palette.primary,
    align: align,
    content: const {'binding': 'monthTitle', 'bindingSubtitle': true},
  );

  void yearText(
    List<double> bounds, {
    String family = 'Fraunces',
    double size = 12,
    int? color,
    String align = 'left',
    double letterSpacing = 4,
    double rotation = 0,
  }) => text(
    'Year',
    bounds,
    'Year',
    family: family,
    size: size,
    color: color ?? palette.accent,
    align: align,
    letterSpacing: letterSpacing,
    rotation: rotation,
    content: const {'binding': 'yearTitle'},
  );

  /// A photo slot; [asset] is only set for previews.
  void photo(
    String name,
    List<double> bounds,
    String? asset, {
    double radius = 4,
    double border = 0,
    int borderColor = white,
    double rotation = 0,
  }) => block(
    'image',
    name,
    bounds,
    rotation: rotation,
    style: {
      'imageFit': 'crop',
      'cornerRadius': radius,
      'borderWidth': border,
      'borderColor': borderColor,
    },
    content: {'assetId': ?asset},
  );

  /// A round photo: square bounds in design units, so pass [format].
  void roundPhoto(
    String name,
    StudioFormat format,
    double left,
    double top,
    double width,
    String? asset, {
    double ring = 3,
    int? ringColor,
  }) => photo(
    name,
    [left, top, width, width * format.designWidth / format.designHeight],
    asset,
    radius: 999,
    border: ring,
    borderColor: ringColor ?? palette.accent,
  );

  /// A logo slot; Studio doesn't block export while it's empty.
  void logo(List<double> bounds) => block(
    'logo',
    'Logo',
    bounds,
    style: const {'imageFit': 'fit', 'cornerRadius': 6},
  );

  void shape(
    String kind,
    List<double> bounds, {
    int? color,
    bool outline = false,
    double strokeWidth = 1.4,
    double opacity = 1,
    double rotation = 0,
    String? name,
    int? zIndex,
  }) => block(
    'shape',
    name ?? '${kind[0].toUpperCase()}${kind.substring(1)}',
    bounds,
    rotation: rotation,
    zIndex: zIndex,
    style: {
      'color': color ?? palette.primary,
      'strokeColor': color ?? palette.primary,
      'strokeWidth': strokeWidth,
      'opacity': opacity,
      if (outline) 'fill': 'none',
    },
    content: {'shape': kind},
  );

  /// A square-looking shape on any page: [width] is a fraction of the width.
  void squareShape(
    String kind,
    StudioFormat format,
    double left,
    double top,
    double width, {
    int? color,
    bool outline = false,
    double strokeWidth = 1.4,
    double opacity = 1,
    double rotation = 0,
  }) => shape(
    kind,
    [left, top, width, width * format.designWidth / format.designHeight],
    color: color,
    outline: outline,
    strokeWidth: strokeWidth,
    opacity: opacity,
    rotation: rotation,
  );

  void rule(List<double> bounds, {int? color}) =>
      shape('line', bounds, color: color ?? palette.accent, strokeWidth: 1);

  void motif(
    String kind,
    String name,
    List<double> bounds, {
    int? color,
    int? accent,
    double opacity = 1,
    double rotation = 0,
    int? seed,
    List<double>? avoid,
  }) => block(
    'decoration',
    name,
    bounds,
    rotation: rotation,
    style: {
      'color': color ?? palette.accent,
      'accent': accent ?? palette.primary,
      'opacity': opacity,
    },
    content: {'kind': kind, 'seed': ?seed, 'avoid': ?avoid},
  );

  /// A titled list with sample rows, or ruled lines with [notes].
  void list(
    List<double> bounds,
    String title, {
    List<String> rows = const [],
    bool notes = false,
    String family = 'Noto Sans Myanmar',
    double size = 10,
    int? ink,
    int? titleColor,
    int? lineColor,
  }) => block(
    'eventList',
    title,
    bounds,
    style: {
      'inkColor': ink ?? palette.ink,
      'mutedColor': palette.muted,
      'titleColor': titleColor ?? palette.primary,
      'lineColor': lineColor ?? palette.line,
      'fontSize': size,
      'fontFamily': family,
    },
    content: {'title': title, 'placeholder': rows, if (notes) 'kind': 'notes'},
  );

  void grid(
    List<double> bounds, {
    String gridLines = 'none',
    String numberFamily = 'Fraunces',
    int? ink,
    int? weekend,
    int? header,
    double rowHeight = 1,
  }) => block(
    'calendarGrid',
    'Calendar grid',
    bounds,
    style: {
      'gridLines': gridLines,
      'inkColor': ink ?? palette.ink,
      'secondaryColor': palette.muted,
      'mutedColor': palette.muted,
      'weekendColor': weekend ?? palette.primary,
      'holidayColor': palette.holiday,
      'headerColor': header ?? palette.primary,
      'lineColor': palette.line,
      'sabbathColor': palette.sabbath,
      'eventColor': palette.primary,
      'numberFont': 'serif',
      'numberFamily': numberFamily,
      'rows': 'auto',
      'rowHeight': rowHeight,
    },
    content: const {'mini': false, 'calendarStyle': 'standard'},
  );

  void legend(
    List<double> bounds, {
    double size = 8,
    String align = 'center',
  }) => block(
    'holidayLegend',
    'Legend',
    bounds,
    style: {
      'inkColor': palette.muted,
      'mutedColor': palette.muted,
      'holidayColor': palette.holiday,
      'sabbathColor': palette.sabbath,
      'moonColor': palette.accent,
      'eventColor': palette.primary,
      'fontSize': size,
      'fontFamily': 'Noto Sans Myanmar',
      'align': align,
    },
    content: const {
      'kind': 'themed',
      'items': ['holiday', 'fullMoon', 'newMoon', 'sabbath'],
    },
  );
}

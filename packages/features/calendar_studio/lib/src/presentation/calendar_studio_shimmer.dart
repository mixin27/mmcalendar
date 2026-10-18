import 'dart:async';
import 'dart:collection' show Queue;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../theme/calendar_studio_theme.dart';

/// A placeholder block with a light sweeping across it while content loads.
/// Holds still when the system asks for reduced motion.
class StudioShimmer extends StatefulWidget {
  const StudioShimmer({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.child,
  });

  final double? width;
  final double? height;
  final double radius;

  /// Optional content laid out inside (e.g. an AspectRatio).
  final Widget? child;

  @override
  State<StudioShimmer> createState() => _StudioShimmerState();
}

class _StudioShimmerState extends State<StudioShimmer>
    with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (_, child) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.6 + _sweep.value * 3.2, -.3),
              end: Alignment(-.6 + _sweep.value * 3.2, .3),
              colors: [tokens.surface2, tokens.surface, tokens.surface2],
            ),
          ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Recently drawn thumbnails, kept as images for this app session so the
/// dashboard shows them at once on the next visit.
abstract final class StudioThumbnailCache {
  static const _capacity = 120;
  static final _images = <String, ui.Image>{};

  /// A clone the caller owns and must dispose, or null.
  static ui.Image? get(String key) {
    final image = _images.remove(key);
    if (image == null) return null;
    _images[key] = image;
    return image.clone();
  }

  static void put(String key, ui.Image image) {
    _images.remove(key)?.dispose();
    _images[key] = image;
    while (_images.length > _capacity) {
      _images.remove(_images.keys.first)?.dispose();
    }
  }

  @visibleForTesting
  static void clear() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }

  @visibleForTesting
  static int get length => _images.length;
}

/// Lets thumbnails build one per frame, so opening a dashboard full of
/// projects never lays out every page in a single frame.
abstract final class _ThumbnailQueue {
  static final _waiting = Queue<VoidCallback>();
  static var _scheduled = false;

  static void add(VoidCallback release) {
    _waiting.add(release);
    _schedule();
  }

  static void remove(VoidCallback release) => _waiting.remove(release);

  static void _schedule() {
    if (_scheduled || _waiting.isEmpty) return;
    _scheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;
        if (_waiting.isNotEmpty) _waiting.removeFirst()();
        _schedule();
      });
    });
  }
}

/// A page thumbnail: the cached image when there is one; otherwise a
/// shimmer until its turn, then the live page, captured once it settles.
class StudioThumbnail extends StatefulWidget {
  const StudioThumbnail({
    super.key,
    required this.cacheKey,
    required this.aspectRatio,
    required this.builder,
    this.captureDelay = const Duration(milliseconds: 900),
  });

  /// Changes whenever the page changes (e.g. project id + updatedAt + page).
  final String cacheKey;
  final double aspectRatio;
  final WidgetBuilder builder;

  /// Time for the live page's images and calendar data to arrive before it
  /// is captured.
  final Duration captureDelay;

  @override
  State<StudioThumbnail> createState() => _StudioThumbnailState();
}

class _StudioThumbnailState extends State<StudioThumbnail> {
  final _boundary = GlobalKey();
  ui.Image? _image;
  var _live = false;
  Timer? _capture;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant StudioThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      _stop();
      _live = false;
      _start();
    }
  }

  void _start() {
    _image?.dispose();
    _image = StudioThumbnailCache.get(widget.cacheKey);
    if (_image == null) _ThumbnailQueue.add(_release);
  }

  void _stop() {
    _ThumbnailQueue.remove(_release);
    _capture?.cancel();
  }

  void _release() {
    if (!mounted) return;
    setState(() => _live = true);
    _capture = Timer(widget.captureDelay, _captureImage);
  }

  Future<void> _captureImage() async {
    final boundary =
        _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (!mounted || boundary == null || boundary.debugNeedsPaint) return;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    try {
      final image = await boundary.toImage(pixelRatio: ratio);
      StudioThumbnailCache.put(widget.cacheKey, image);
    } catch (_) {
      // Not captured; the live page keeps showing.
    }
  }

  @override
  void dispose() {
    _stop();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: image != null
          ? RawImage(image: image, fit: BoxFit.fill)
          : _live
          ? RepaintBoundary(key: _boundary, child: widget.builder(context))
          : const StudioShimmer(radius: 2),
    );
  }
}

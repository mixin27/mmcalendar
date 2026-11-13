import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum WearShape { round, square }

/// Builds with the screen's shape, which MainActivity reports on the
/// `watch_shape` channel. Until it answers (and in tests) the screen is
/// taken as round, as nearly every Wear OS watch is.
class WatchShape extends StatefulWidget {
  const WatchShape({required this.builder, this.child, super.key});

  static const channel = MethodChannel('watch_shape');

  final ValueWidgetBuilder<WearShape> builder;
  final Widget? child;

  static WearShape? _cached;

  static Future<WearShape> load() async {
    if (_cached case final shape?) return shape;
    try {
      final round = await channel.invokeMethod<bool>('isRound') ?? true;
      return _cached = round ? WearShape.round : WearShape.square;
    } on MissingPluginException {
      return WearShape.round;
    } on PlatformException {
      return WearShape.round;
    }
  }

  @override
  State<WatchShape> createState() => _WatchShapeState();
}

class _WatchShapeState extends State<WatchShape> {
  WearShape _shape = WatchShape._cached ?? WearShape.round;

  @override
  void initState() {
    super.initState();
    WatchShape.load().then((shape) {
      if (mounted && shape != _shape) setState(() => _shape = shape);
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _shape, widget.child);
}

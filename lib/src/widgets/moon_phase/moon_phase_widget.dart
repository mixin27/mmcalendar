import 'package:flutter/material.dart';

import 'moon_painter.dart';
import 'moon_settings.dart';

class MoonPhaseWidget extends StatelessWidget {
  const MoonPhaseWidget({
    super.key,
    required this.date,
    this.settings = const MoonSettings(),
  });

  ///DateTime to show.
  ///Even hour, minutes, and seconds are calculated for MoonWidget
  final DateTime date;

  final MoonSettings settings;

  @override
  Widget build(BuildContext context) {
    final scale = settings.size / (settings.resolution * 2);

    return SizedBox(
      width: settings.size,
      height: settings.size,
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: CustomPaint(
            painter: MoonPainter(settings: settings, date: date),
          ),
        ),
      ),
    );
  }
}

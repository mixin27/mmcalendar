import 'dart:math';

import 'package:flutter/material.dart';

import 'moon_phase.dart';
import 'moon_settings.dart';

class MoonPainter extends CustomPainter {
  MoonPainter({Key? key, required this.settings, required this.date});

  final MoonSettings settings;
  final DateTime date;

  final paintDark = Paint();
  final paintLight = Paint();
  final moonPhase = MoonPhase();

  @override
  void paint(Canvas canvas, Size size) {
    double radius = settings.resolution;

    int width = radius.toInt() * 2;
    int height = radius.toInt() * 2;
    double phaseAngle = moonPhase.getPhaseAngle(date);

    double xcenter = 0;
    double ycenter = 0;

    try {
      paintLight.color = settings.lightColor;
      canvas.drawCircle(const Offset(0, 1), radius, paintLight);
    } catch (e) {
      radius = min(width, height) * 0.4;
      paintLight.color = settings.lightColor;

      Rect oval = Rect.fromLTRB(
        xcenter - radius,
        ycenter - radius,
        xcenter + radius,
        ycenter + radius,
      );

      canvas.drawOval(oval, paintLight);
    }

    double positionAngle = pi - phaseAngle;
    if (positionAngle < 0.0) {
      positionAngle += 2.0 * pi;
    }

    paintDark.color = settings.earthshineColor;

    double cosTerm = cos(positionAngle);

    double rsquared = radius * radius;
    double whichQuarter = ((positionAngle * 2.0 / pi) + 4) % 4;

    for (int j = 0; j < radius; ++j) {
      double rrf = sqrt(rsquared - j * j);
      double rr = rrf;
      double xx = rrf * cosTerm;
      double x1 = xcenter - (whichQuarter < 2 ? rr : xx);
      double w = rr + xx;

      canvas.drawRect(
        Rect.fromLTRB(x1, ycenter - j, w + x1, ycenter - j + 2),
        paintDark,
      );
      canvas.drawRect(
        Rect.fromLTRB(x1, ycenter + j, w + x1, ycenter + j + 2),
        paintDark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

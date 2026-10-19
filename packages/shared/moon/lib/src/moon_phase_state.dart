import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Where the moon is in its cycle at one instant, as seen from Earth.
///
/// Computed from the Julian day with the low-precision series in Meeus,
/// *Astronomical Algorithms* (ch. 47–49): mean elongation, the sun's and
/// moon's mean anomalies, and the main periodic terms of the phase angle.
/// That is accurate to well under 1% illumination, which is far below what
/// a glyph can show.
///
/// The shape is the real sky's; Myanmar calendar labels (full moon,
/// new moon, Sabbath) still come from the calendar itself.
@immutable
class MoonPhaseState {
  const MoonPhaseState({
    required this.illumination,
    required this.isWaxing,
    required this.phaseAngle,
  });

  /// [instant] is converted to UTC.
  factory MoonPhaseState.at(DateTime instant) {
    final julianDay =
        instant.toUtc().millisecondsSinceEpoch / Duration.millisecondsPerDay +
        2440587.5;
    final t = (julianDay - 2451545.0) / 36525;
    final elongation = _normalize(297.8501921 + 445267.1114034 * t);
    final sunAnomaly = _normalize(357.5291092 + 35999.0502909 * t);
    final moonAnomaly = _normalize(134.9633964 + 477198.8675055 * t);

    var angle =
        180 -
        elongation -
        6.289 * _sin(moonAnomaly) +
        2.100 * _sin(sunAnomaly) -
        1.274 * _sin(2 * elongation - moonAnomaly) -
        0.658 * _sin(2 * elongation) -
        0.214 * _sin(2 * moonAnomaly) -
        0.110 * _sin(elongation);
    angle = _normalize(angle);
    if (angle > 180) angle = 360 - angle;

    return MoonPhaseState(
      illumination: (1 + math.cos(angle * _radians)) / 2,
      isWaxing: elongation < 180,
      phaseAngle: angle,
    );
  }

  /// A moon with a given lit fraction, for legends and phase pickers that
  /// show a kind of phase rather than a date.
  factory MoonPhaseState.ofIllumination(
    double illumination, {
    required bool isWaxing,
  }) {
    final k = illumination.clamp(0.0, 1.0);
    return MoonPhaseState(
      illumination: k,
      isWaxing: isWaxing,
      phaseAngle: math.acos(2 * k - 1) / _radians,
    );
  }

  /// The typical look of a Myanmar calendar phase (0 waxing, 1 full,
  /// 2 waning, 3 new): quarters for the fortnights.
  factory MoonPhaseState.typical(int myanmarPhase) => switch (myanmarPhase) {
    1 => MoonPhaseState.ofIllumination(1, isWaxing: true),
    2 => MoonPhaseState.ofIllumination(.5, isWaxing: false),
    3 => MoonPhaseState.ofIllumination(0, isWaxing: true),
    _ => MoonPhaseState.ofIllumination(.5, isWaxing: true),
  };

  /// The moon on the evening of [date] (18:30 local time), when people look
  /// for it. [utcOffset] defaults to Myanmar time.
  factory MoonPhaseState.evening(
    DateTime date, {
    Duration utcOffset = myanmarUtcOffset,
  }) => MoonPhaseState.at(
    DateTime.utc(date.year, date.month, date.day, 18, 30).subtract(utcOffset),
  );

  static const myanmarUtcOffset = Duration(hours: 6, minutes: 30);
  static const synodicMonth = 29.530588853;

  /// Lit fraction of the disc, 0 (new) to 1 (full).
  final double illumination;

  /// True from new moon to full moon (the lit limb faces the setting sun).
  final bool isWaxing;

  /// Sun–moon–Earth angle in degrees: 0 at full moon, 180 at new moon.
  final double phaseAngle;

  /// Position in the cycle, 0 (new) → 0.5 (full) → 1 (new).
  double get cycle =>
      isWaxing ? (1 - phaseAngle / 180) / 2 : 0.5 + phaseAngle / 360;

  /// Approximate days since the last new moon.
  double get age => cycle * synodicMonth;

  int get percentLit => (illumination * 100).round();

  static const _radians = math.pi / 180;
  static double _sin(double degrees) => math.sin(degrees * _radians);
  static double _normalize(double degrees) => (degrees % 360 + 360) % 360;

  @override
  bool operator ==(Object other) =>
      other is MoonPhaseState &&
      other.illumination == illumination &&
      other.isWaxing == isWaxing &&
      other.phaseAngle == phaseAngle;

  @override
  int get hashCode => Object.hash(illumination, isWaxing, phaseAngle);

  @override
  String toString() =>
      'MoonPhaseState($percentLit% lit, ${isWaxing ? 'waxing' : 'waning'})';
}

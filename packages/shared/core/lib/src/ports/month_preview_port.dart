import 'package:flutter/widgets.dart';

/// Shared UI boundary for month preview rendering.
///
/// Implementations can provide feature-specific widgets while consumers remain
/// decoupled from concrete feature packages.
abstract interface class MonthPreviewPort {
  Widget buildMonthPreview({
    required DateTime date,
    void Function(DateTime date)? onDateTap,
  });
}

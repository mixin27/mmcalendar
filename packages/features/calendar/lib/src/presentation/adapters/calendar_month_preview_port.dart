import 'package:shared_core/shared_core.dart';
import 'package:flutter/widgets.dart';

import '../widgets/month_preview.dart';

class CalendarMonthPreviewPort implements MonthPreviewPort {
  @override
  Widget buildMonthPreview({
    required DateTime date,
    void Function(DateTime date)? onDateTap,
  }) {
    return MonthPreview(date: date, onDateTap: onDateTap);
  }
}

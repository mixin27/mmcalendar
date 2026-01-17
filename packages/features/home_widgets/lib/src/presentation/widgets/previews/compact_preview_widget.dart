import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

/// Compact Date Widget Preview
class CompactPreviewWidget extends StatelessWidget {
  const CompactPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    MyanmarCalendar.setLanguage(Language.myanmar);
    final myanmarDate = MyanmarCalendar.fromWestern(
      today.year,
      today.month,
      today.day,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Western Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                myanmarDate.formatWestern("%dd"),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  myanmarDate.formatWestern("%M"),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Myanmar Date
          Text(
            '${myanmarDate.formatMyanmar('&y &M &P &f')} ရက်',
            style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

/// Myanmar Month Widget Preview
class MyanmarMonthPreviewWidget extends StatelessWidget {
  const MyanmarMonthPreviewWidget({super.key});

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
          begin: Alignment(-1.0, -1.0),
          end: Alignment(1.0, 1.0),
          colors: [Color(0xFF37474F), Color(0xFF455A64), Color(0xFF37474F)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Header
          Text(
            myanmarDate.formatMyanmar("&M"),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_getMonthName(today.month)} ${today.year}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          // Weekday headers
          Row(
            children: ['နွေ', 'လာ', 'ဂါ', 'ဟူး', 'ကြာ', 'သော', 'နေ']
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 2),
          // Calendar grid (simplified for preview)
          Expanded(child: _MyanmarMonthGrid(currentDay: today.day)),
          const SizedBox(height: 6),
          // Today info
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${myanmarDate.formatMyanmar('&M &P &ff')} ${TranslationService.translate("Yat")}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}

/// Simplified Myanmar Month Grid for Preview
class _MyanmarMonthGrid extends StatelessWidget {
  final int currentDay;

  const _MyanmarMonthGrid({required this.currentDay});

  @override
  Widget build(BuildContext context) {
    // Generate sample grid (6 rows × 7 days = 42 cells)
    return Column(
      children: List.generate(6, (row) {
        return Expanded(
          child: Row(
            children: List.generate(7, (col) {
              final dayNum = row * 7 + col + 1;
              final isToday = dayNum == currentDay && row < 5;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFFFD700)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _formatSampleDay(dayNum, row),
                      style: TextStyle(
                        fontSize: 9,
                        color: isToday ? Colors.black : Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  String _formatSampleDay(int dayNum, int row) {
    if (row >= 5 || dayNum > 30) return '';

    // Alternate between waxing and waning
    final phase = (dayNum <= 15) ? 'လဆန်း' : 'လဆုတ်';
    final day = (dayNum <= 15) ? dayNum : dayNum - 15;
    return '$phase\n${_convertToMyanmar(day)}';
  }

  String _convertToMyanmar(int num) {
    const digits = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];
    return num.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}

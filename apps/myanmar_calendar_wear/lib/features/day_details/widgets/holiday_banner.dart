import 'package:flutter/material.dart';

/// The day's holidays, titled as on the phone.
class HolidayBanner extends StatelessWidget {
  const HolidayBanner({required this.holidays, super.key});

  final List<String> holidays;

  @override
  Widget build(BuildContext context) {
    if (holidays.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade900.withValues(alpha: 0.5),
            Colors.pink.shade900.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade600.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration, color: Colors.red.shade200, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final holiday in holidays)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      holiday,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

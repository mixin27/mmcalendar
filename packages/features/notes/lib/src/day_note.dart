import 'package:flutter/foundation.dart';

/// The note written on one calendar [date].
@immutable
class DayNote {
  const DayNote({
    required this.date,
    required this.text,
    required this.updatedAt,
  });

  /// The day, at midnight.
  final DateTime date;
  final String text;
  final DateTime updatedAt;

  /// The start of the note for rows: its first three lines, cut at about
  /// 140 characters.
  String get preview {
    final lines = text.trim().split('\n').where((l) => l.trim().isNotEmpty);
    final short = lines.take(3).join('\n');
    final cut = short.length > 140 ? '${short.substring(0, 139)}…' : short;
    return lines.length > 3 && !cut.endsWith('…') ? '$cut…' : cut;
  }

  @override
  bool operator ==(Object other) =>
      other is DayNote &&
      other.date == date &&
      other.text == text &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(date, text, updatedAt);
}

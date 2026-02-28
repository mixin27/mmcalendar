import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// Represents data to be displayed in home widgets
class WidgetData extends Equatable {
  final String myanmarDate;
  final String westernDate;
  final String moonPhase;
  final int moonPhaseValue;
  final String moonPhaseEmoji;
  final int fortnightDay;
  final String fortnightDayText;
  final List<String> holidays;
  final String? sabbathInfo;
  final String? yatyazaInfo;
  final String? pyathadaInfo;
  final List<String> astrologicalDays;
  final DateTime lastUpdated;
  final List<String> weekdayNames;
  final List<String> moonPhaseNames;
  final String nextMoonPhase;
  final CompleteDate? completeDate;

  const WidgetData({
    required this.myanmarDate,
    required this.westernDate,
    required this.moonPhase,
    required this.moonPhaseValue,
    required this.moonPhaseEmoji,
    required this.fortnightDay,
    required this.fortnightDayText,
    required this.holidays,
    required this.astrologicalDays,
    this.sabbathInfo,
    this.yatyazaInfo,
    this.pyathadaInfo,
    required this.lastUpdated,
    required this.weekdayNames,
    required this.moonPhaseNames,
    required this.nextMoonPhase,
    this.completeDate,
  });

  @override
  List<Object?> get props => [
    myanmarDate,
    westernDate,
    moonPhase,
    moonPhaseValue,
    moonPhaseEmoji,
    fortnightDay,
    fortnightDayText,
    holidays,
    astrologicalDays,
    sabbathInfo,
    yatyazaInfo,
    pyathadaInfo,
    lastUpdated,
    nextMoonPhase,
    completeDate,
  ];

  /// Convert to JSON for widget storage
  Map<String, dynamic> toJson() {
    return {
      'myanmarDate': myanmarDate,
      'westernDate': westernDate,
      'moonPhase': moonPhase,
      'moonPhaseValue': moonPhaseValue,
      'moonPhaseEmoji': moonPhaseEmoji,
      'fortnightDay': fortnightDay,
      'fortnightDayText': fortnightDayText,
      'holidays': holidays,
      'astrologicalDays': astrologicalDays,
      'sabbathInfo': sabbathInfo,
      'yatyazaInfo': yatyazaInfo,
      'pyathadaInfo': pyathadaInfo,
      'lastUpdated': lastUpdated.toIso8601String(),
      'nextMoonPhase': nextMoonPhase,
    };
  }

  /// Create from JSON
  factory WidgetData.fromJson(Map<String, dynamic> json) {
    return WidgetData(
      myanmarDate: json['myanmarDate'] as String,
      westernDate: json['westernDate'] as String,
      moonPhase: json['moonPhase'] as String,
      moonPhaseValue: json['moonPhaseValue'] as int,
      moonPhaseEmoji: json['moonPhaseEmoji'] as String,
      fortnightDay: json['fortnightDay'] as int,
      fortnightDayText: json['fortnightDayText'] as String,
      holidays: (json['holidays'] as List<dynamic>).cast<String>(),
      astrologicalDays: (json['astrologicalDays'] as List<dynamic>)
          .cast<String>(),
      sabbathInfo: json['sabbathInfo'] as String?,
      yatyazaInfo: json['yatyazaInfo'] as String?,
      pyathadaInfo: json['pyathadaInfo'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      weekdayNames: (json['weekdayNames'] as List<dynamic>).cast<String>(),
      moonPhaseNames: (json['moonPhaseNames'] as List<dynamic>).cast<String>(),
      nextMoonPhase: json['nextMoonPhase'] as String,
    );
  }
}

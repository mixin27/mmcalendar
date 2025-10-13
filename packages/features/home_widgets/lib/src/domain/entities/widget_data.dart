import 'package:equatable/equatable.dart';

/// Represents data to be displayed in home widgets
class WidgetData extends Equatable {
  final String myanmarDate;
  final String westernDate;
  final String moonPhase;
  final int moonPhaseValue;
  final String moonPhaseEmoji;
  final int fortnightDay;
  final List<String> holidays;
  final String? sabbathInfo;
  final String? yatyazaInfo;
  final String? pyathadaInfo;
  final DateTime lastUpdated;

  const WidgetData({
    required this.myanmarDate,
    required this.westernDate,
    required this.moonPhase,
    required this.moonPhaseValue,
    required this.moonPhaseEmoji,
    required this.fortnightDay,
    required this.holidays,
    this.sabbathInfo,
    this.yatyazaInfo,
    this.pyathadaInfo,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    myanmarDate,
    westernDate,
    moonPhase,
    moonPhaseValue,
    moonPhaseEmoji,
    fortnightDay,
    holidays,
    sabbathInfo,
    yatyazaInfo,
    pyathadaInfo,
    lastUpdated,
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
      'holidays': holidays,
      'sabbathInfo': sabbathInfo,
      'yatyazaInfo': yatyazaInfo,
      'pyathadaInfo': pyathadaInfo,
      'lastUpdated': lastUpdated.toIso8601String(),
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
      holidays: (json['holidays'] as List<dynamic>).cast<String>(),
      sabbathInfo: json['sabbathInfo'] as String?,
      yatyazaInfo: json['yatyazaInfo'] as String?,
      pyathadaInfo: json['pyathadaInfo'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

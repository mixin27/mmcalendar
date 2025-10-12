import 'package:equatable/equatable.dart';

enum WidgetSize { small, medium, large }

enum WidgetTheme { light, dark, traditional, auto }

class WidgetConfig extends Equatable {
  final WidgetSize size;
  final WidgetTheme theme;
  final bool showHolidays;
  final bool showAstrology;
  final bool showMyanmarDate;
  final bool showWesternDate;
  final String language; // 'my' or 'en'

  const WidgetConfig({
    required this.size,
    required this.theme,
    required this.showHolidays,
    required this.showAstrology,
    required this.showMyanmarDate,
    required this.showWesternDate,
    required this.language,
  });

  const WidgetConfig.defaults()
    : size = WidgetSize.medium,
      theme = WidgetTheme.auto,
      showHolidays = true,
      showAstrology = true,
      showMyanmarDate = true,
      showWesternDate = true,
      language = 'my';

  @override
  List<Object?> get props => [
    size,
    theme,
    showHolidays,
    showAstrology,
    showMyanmarDate,
    showWesternDate,
    language,
  ];

  WidgetConfig copyWith({
    WidgetSize? size,
    WidgetTheme? theme,
    bool? showHolidays,
    bool? showAstrology,
    bool? showMyanmarDate,
    bool? showWesternDate,
    String? language,
  }) {
    return WidgetConfig(
      size: size ?? this.size,
      theme: theme ?? this.theme,
      showHolidays: showHolidays ?? this.showHolidays,
      showAstrology: showAstrology ?? this.showAstrology,
      showMyanmarDate: showMyanmarDate ?? this.showMyanmarDate,
      showWesternDate: showWesternDate ?? this.showWesternDate,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size.name,
      'theme': theme.name,
      'showHolidays': showHolidays,
      'showAstrology': showAstrology,
      'showMyanmarDate': showMyanmarDate,
      'showWesternDate': showWesternDate,
      'language': language,
    };
  }

  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      size: WidgetSize.values.firstWhere(
        (e) => e.name == json['size'],
        orElse: () => WidgetSize.medium,
      ),
      theme: WidgetTheme.values.firstWhere(
        (e) => e.name == json['theme'],
        orElse: () => WidgetTheme.auto,
      ),
      showHolidays: json['showHolidays'] as bool? ?? true,
      showAstrology: json['showAstrology'] as bool? ?? true,
      showMyanmarDate: json['showMyanmarDate'] as bool? ?? true,
      showWesternDate: json['showWesternDate'] as bool? ?? true,
      language: json['language'] as String? ?? 'my',
    );
  }
}

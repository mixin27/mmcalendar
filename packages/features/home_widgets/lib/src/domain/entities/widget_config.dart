import 'package:equatable/equatable.dart';

import '../../data/payload/widget_palettes.dart';

export '../../data/payload/widget_palettes.dart' show WidgetStyleId;

/// What a Countdown widget counts to unless set on the widget itself.
enum CountdownTarget {
  fullMoon,
  newMoon,
  sabbath,
  thingyan;

  static CountdownTarget fromName(String? name) =>
      values.firstWhere((t) => t.name == name, orElse: () => fullMoon);
}

/// The defaults every widget starts from. Each widget can override them
/// (Edit Widget on iPhone, Reconfigure on Android).
class WidgetConfig extends Equatable {
  final WidgetStyleId style;
  final bool showHolidays;
  final bool showSabbath;
  final bool showAstrology;
  final bool showEvents;
  final CountdownTarget countdownTarget;

  /// Mirrors the app's calendar language code.
  final String language;

  const WidgetConfig({
    required this.style,
    required this.showHolidays,
    required this.showSabbath,
    required this.showAstrology,
    required this.showEvents,
    required this.countdownTarget,
    required this.language,
  });

  const WidgetConfig.defaults()
    : style = WidgetStyleId.app,
      showHolidays = true,
      showSabbath = true,
      showAstrology = true,
      showEvents = true,
      countdownTarget = CountdownTarget.fullMoon,
      language = 'en';

  @override
  List<Object?> get props => [
    style,
    showHolidays,
    showSabbath,
    showAstrology,
    showEvents,
    countdownTarget,
    language,
  ];

  WidgetConfig copyWith({
    WidgetStyleId? style,
    bool? showHolidays,
    bool? showSabbath,
    bool? showAstrology,
    bool? showEvents,
    CountdownTarget? countdownTarget,
    String? language,
  }) {
    return WidgetConfig(
      style: style ?? this.style,
      showHolidays: showHolidays ?? this.showHolidays,
      showSabbath: showSabbath ?? this.showSabbath,
      showAstrology: showAstrology ?? this.showAstrology,
      showEvents: showEvents ?? this.showEvents,
      countdownTarget: countdownTarget ?? this.countdownTarget,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
    'style': style.name,
    'showHolidays': showHolidays,
    'showSabbath': showSabbath,
    'showAstrology': showAstrology,
    'showEvents': showEvents,
    'countdownTarget': countdownTarget.name,
    'language': language,
  };

  /// What the native widgets read as `prefs`.
  Map<String, Object?> toPayload() => {
    'style': style.name,
    'hol': showHolidays,
    'sab': showSabbath,
    'ast': showAstrology,
    'ev': showEvents,
    'cd': countdownTarget.name,
  };

  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      style: json['style'] is String
          ? WidgetStyleId.fromName(json['style'] as String)
          : _styleFromTheme(json['theme'] as String?),
      showHolidays: json['showHolidays'] as bool? ?? true,
      showSabbath: json['showSabbath'] as bool? ?? true,
      showAstrology: json['showAstrology'] as bool? ?? true,
      showEvents: json['showEvents'] as bool? ?? true,
      countdownTarget: CountdownTarget.fromName(
        json['countdownTarget'] as String?,
      ),
      language: json['language'] as String? ?? 'my',
    );
  }

  /// v1 themes: Traditional becomes Pagoda, plain light and dark become
  /// Plain, and Auto and the gradients follow the app.
  static WidgetStyleId _styleFromTheme(String? theme) => switch (theme) {
    'traditional' => WidgetStyleId.pagoda,
    'light' || 'dark' => WidgetStyleId.plain,
    _ => WidgetStyleId.app,
  };
}

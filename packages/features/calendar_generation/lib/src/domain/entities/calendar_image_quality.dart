enum CalendarImageQuality { screen, print }

extension CalendarImageQualityX on CalendarImageQuality {
  String get label => switch (this) {
    CalendarImageQuality.screen => 'Screen (150 DPI)',
    CalendarImageQuality.print => 'Print (300 DPI)',
  };

  int get defaultDpi => switch (this) {
    CalendarImageQuality.screen => 150,
    CalendarImageQuality.print => 300,
  };

  int get defaultJpegQuality => switch (this) {
    CalendarImageQuality.screen => 78,
    CalendarImageQuality.print => 88,
  };

  int get defaultTargetSizeKb => switch (this) {
    CalendarImageQuality.screen => 900,
    CalendarImageQuality.print => 2600,
  };
}

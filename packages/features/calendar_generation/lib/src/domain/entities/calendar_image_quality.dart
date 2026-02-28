enum CalendarImageQuality { screen, print }

extension CalendarImageQualityX on CalendarImageQuality {
  String get label => switch (this) {
    CalendarImageQuality.screen => 'Screen (150 DPI)',
    CalendarImageQuality.print => 'Print (300 DPI)',
  };
}

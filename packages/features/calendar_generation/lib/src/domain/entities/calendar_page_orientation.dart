enum CalendarPageOrientation { portrait, landscape }

extension CalendarPageOrientationX on CalendarPageOrientation {
  String get label => switch (this) {
    CalendarPageOrientation.portrait => 'Portrait',
    CalendarPageOrientation.landscape => 'Landscape',
  };
}

enum CalendarLandscapeDecorationAreaSide { left, right }

extension CalendarLandscapeDecorationAreaSideX
    on CalendarLandscapeDecorationAreaSide {
  String get label => switch (this) {
    CalendarLandscapeDecorationAreaSide.left => 'Left',
    CalendarLandscapeDecorationAreaSide.right => 'Right',
  };
}

enum CalendarPaperSize { a4, letter }

extension CalendarPaperSizeX on CalendarPaperSize {
  String get label => switch (this) {
    CalendarPaperSize.a4 => 'A4',
    CalendarPaperSize.letter => 'Letter',
  };
}

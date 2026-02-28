import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

String translateSentence(String sentence) {
  final words = sentence.split(' ');
  if (words.length <= 1) {
    return TranslationService.translateTo(
      sentence,
      MyanmarCalendar.currentLanguage,
    );
  }
  return words
      .map(
        (word) => TranslationService.translateTo(
          word,
          MyanmarCalendar.currentLanguage,
        ),
      )
      .join(' ');
}

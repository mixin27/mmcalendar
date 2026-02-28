import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

String translateNumbers(String text, {Language? language}) {
  final currentLang = language ?? MyanmarCalendar.currentLanguage;

  if (!TranslationService.shouldTranslateDigits(currentLang)) {
    return text;
  }

  var result = text;
  for (int i = 0; i <= 9; i++) {
    result = result.replaceAll(
      i.toString(),
      TranslationService.translateTo(i.toString(), currentLang),
    );
  }
  return result;
}

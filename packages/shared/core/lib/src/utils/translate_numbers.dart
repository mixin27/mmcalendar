import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

String translateNumbers(String text) {
  final currentLang = TranslationService.currentLanguage;

  // Only translate numbers for Myanmar languages
  if (currentLang == Language.myanmar || currentLang == Language.zawgyi) {
    var result = text;
    for (int i = 0; i <= 9; i++) {
      result = result.replaceAll(
        i.toString(),
        TranslationService.translate(i.toString()),
      );
    }
    return result;
  }

  return text;
}

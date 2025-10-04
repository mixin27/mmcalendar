import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

String translateSentence(String sentence) {
  final words = sentence.split(' ');
  if (words.length <= 1) return TranslationService.translate(sentence);
  return words.map((word) => TranslationService.translate(word)).join(' ');
}

/// Translate numbers to the current language
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

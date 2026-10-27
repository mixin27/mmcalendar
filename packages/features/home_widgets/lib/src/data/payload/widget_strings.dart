import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

/// Every word a native widget prints, in the widget's calendar language, so
/// Swift and Kotlin never hard-code text. Calendar words (weekdays, months,
/// moon phases, astrology names) come from the calendar package; the few
/// widget labels are written here in Myanmar and English, and other calendar
/// languages use the English labels (Zawgyi and Shan devices may not render
/// Unicode Myanmar labels).
abstract final class WidgetStrings {
  static const _my = {
    'today': 'ယနေ့',
    'tomorrow': 'မနက်ဖြန်',
    'inDays': '{n} ရက်အကြာ',
    'daysUnit': 'ရက်',
    'comingUp': 'လာမည့်နေ့ထူးများ',
    'events': 'ပွဲများ',
    'noEvents': 'ပွဲမရှိပါ',
    'allDay': 'တစ်နေ့လုံး',
    'nextGoodDay': 'နောက်ရက်ကောင်း',
    'goodDay': 'မင်္ဂလာကိစ္စ အစပြုရန် ကောင်း',
    'avoidDay': 'အစပြုခြင်း၊ ခရီးထွက်ခြင်း ရှောင်ရန်',
    'plainDay': 'ထူးခြားသော ဗေဒင်နေ့ မဟုတ်ပါ',
    'myanmarYear': 'မြန်မာနှစ်',
    'thingyan': 'သင်္ကြန်',
    'fullMoonIn': 'လပြည့်ရန် {n} ရက်',
    'newMoonIn': 'လကွယ်ရန် {n} ရက်',
    'holidays': 'ပိတ်ရက်',
  };

  static const _en = {
    'today': 'Today',
    'tomorrow': 'Tomorrow',
    'inDays': 'in {n} days',
    'daysUnit': 'days',
    'comingUp': 'Coming up',
    'events': 'Events',
    'noEvents': 'No events',
    'allDay': 'All day',
    'nextGoodDay': 'Next good day',
    'goodDay': 'Good for new beginnings',
    'avoidDay': 'Avoid beginnings and travel',
    'plainDay': 'No special astrological day',
    'myanmarYear': 'Myanmar year',
    'thingyan': 'Thingyan',
    'fullMoonIn': 'Full moon in {n} days',
    'newMoonIn': 'New moon in {n} days',
    'holidays': 'Holiday',
  };

  /// The widget labels plus calendar words for [language]. Western dates
  /// use `westernDigits`: English with [englishWesternDigits].
  static Map<String, Object> forLanguage(
    Language language, {
    bool englishWesternDigits = false,
  }) {
    final labels = language == Language.myanmar ? _my : _en;
    String t(String key) => TranslationService.translateTo(key, language);
    // The package counts weekdays from Saturday (0); widgets count from
    // Sunday (0), like DateTime.weekday % 7.
    List<String> weekdays({required bool short}) => [
      for (var sunday = 0; sunday < 7; sunday++)
        short
            ? TranslationService.getShortWeekdayName((sunday + 1) % 7, language)
            : TranslationService.getWeekdayName((sunday + 1) % 7, language),
    ];
    return {
      ...labels,
      'digits': translateNumbers('0123456789', language: language),
      'westernDigits': englishWesternDigits
          ? '0123456789'
          : translateNumbers('0123456789', language: language),
      'sabbath': t('Sabbath'),
      'sabbathEve': t('Sabbath Eve'),
      'moonPhases': [
        for (var i = 0; i < 4; i++)
          TranslationService.getMoonPhaseName(i, language),
      ],
      'weekdays': weekdays(short: false),
      'weekdaysShort': weekdays(short: true),
      'months': [
        for (var m = 1; m <= 12; m++)
          TranslationService.getWesternMonthName(m, language),
      ],
      'monthsShort': [
        for (var m = 1; m <= 12; m++)
          TranslationService.getShortWesternMonthName(m, language),
      ],
    };
  }
}

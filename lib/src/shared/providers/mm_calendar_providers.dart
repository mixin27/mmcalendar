import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:mmcalendar/src/utils/shared_prefs/preference_manager.dart';
import 'package:mmcalendar/src/widgets/settings/calendar_language_list_tile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mm_calendar_providers.g.dart';

@Riverpod(keepAlive: true)
MmCalendar mmCalendar(MmCalendarRef ref) {
  final config = ref.watch(mmCalendarConfigControllerProvider);
  return MmCalendar(config: config);
}

@Riverpod(keepAlive: true)
class MmCalendarConfigController extends _$MmCalendarConfigController {
  Language _fetchLanguage() {
    final prefs = ref.read(preferenceManagerProvider);

    final language = prefs.getData<String>(keyCalendarLang);

    return switch (language) {
      'Language.english' => Language.english,
      'Language.karen' => Language.karen,
      'Language.mon' => Language.mon,
      'Language.tai' => Language.tai,
      'Language.zawgyi' => Language.zawgyi,
      _ => Language.myanmar,
    };
  }

  @override
  MmCalendarConfig build() {
    final language = _fetchLanguage();
    return MmCalendarConfig(language: language);
  }

  void setLanguage(Language language) {
    final prefs = ref.read(preferenceManagerProvider);
    prefs.setData<String>(language.toString(), keyCalendarLang);
    state = MmCalendarConfig(language: language);
  }
}

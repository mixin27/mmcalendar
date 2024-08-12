import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/utils/shared_prefs/preference_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_language_list_tile.g.dart';

const PreferenceKey keyCalendarLang = 'key_cal_lang';

class CalendarLanguageListTile extends HookConsumerWidget {
  const CalendarLanguageListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(calendarLanguageControllerProvider);

    void changeCalendarLanguage(Language lang) {
      ref
          .read(calendarLanguageControllerProvider.notifier)
          .setCalendarLanguage(lang);
      Navigator.of(context).pop();
    }

    void handleTap() {
      showAdaptiveDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () => changeCalendarLanguage(Language.myanmar),
                title: const Text('Myanmar (Unicode)'),
                trailing: language == Language.myanmar
                    ? const Icon(Icons.check_outlined, color: Colors.green)
                    : null,
              ),
              ListTile(
                onTap: () => changeCalendarLanguage(Language.zawgyi),
                title: const Text('Myanmar (Zawgyi)'),
                trailing: language == Language.zawgyi
                    ? const Icon(Icons.check_outlined, color: Colors.green)
                    : null,
              ),
              ListTile(
                onTap: () => changeCalendarLanguage(Language.english),
                title: const Text('English'),
                trailing: language == Language.english
                    ? const Icon(Icons.check_outlined, color: Colors.green)
                    : null,
              ),
              ListTile(
                onTap: () => changeCalendarLanguage(Language.karen),
                title: const Text('Karen'),
                trailing: language == Language.karen
                    ? const Icon(Icons.check_outlined, color: Colors.green)
                    : null,
              ),
              ListTile(
                onTap: () => changeCalendarLanguage(Language.mon),
                title: const Text('Mon'),
                trailing: language == Language.mon
                    ? const Icon(Icons.check_outlined, color: Colors.green)
                    : null,
              ),
              ListTile(
                onTap: () => changeCalendarLanguage(Language.tai),
                title: const Text('Tai'),
                trailing: language == Language.tai
                    ? const Icon(Icons.check_outlined, color: Colors.green)
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    return ListTile(
      onTap: handleTap,
      leading: const Icon(IconlyLight.calendar),
      title: const Text('Calendar Language'),
      subtitle: const Text('English, myanmar, karen ...'),
    );
  }
}

@Riverpod(keepAlive: true)
class CalendarLanguageController extends _$CalendarLanguageController {
  Language _getLanguageFromCached() {
    final prefs = ref.read(preferenceManagerProvider);

    final language = prefs.getData<String>(keyCalendarLang);
    log('lang: $language');

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
  Language build() {
    return _getLanguageFromCached();
  }

  void setCalendarLanguage(Language language) {
    final prefs = ref.read(preferenceManagerProvider);
    prefs.setData<String>(language.toString(), keyCalendarLang);

    state = _getLanguageFromCached();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/shared/providers/mm_calendar_providers.dart';
import 'package:mmcalendar/src/utils/shared_prefs/preference_manager.dart';

const PreferenceKey keyCalendarLang = 'key_cal_lang';

class CalendarLanguageListTile extends HookConsumerWidget {
  const CalendarLanguageListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mmCalendarConfig = ref.watch(mmCalendarConfigControllerProvider);

    void changeCalendarLanguage(Language lang) {
      ref.read(mmCalendarConfigControllerProvider.notifier).setLanguage(lang);
      Navigator.of(context).pop();
    }

    void handleTap() {
      showAdaptiveDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Theme'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  onTap: () => changeCalendarLanguage(Language.myanmar),
                  title: const Text('Myanmar (Unicode)'),
                  trailing: mmCalendarConfig.language == Language.myanmar
                      ? const Icon(Icons.check_outlined, color: Colors.green)
                      : null,
                ),
                ListTile(
                  onTap: () => changeCalendarLanguage(Language.zawgyi),
                  title: const Text('Myanmar (Zawgyi)'),
                  trailing: mmCalendarConfig.language == Language.zawgyi
                      ? const Icon(Icons.check_outlined, color: Colors.green)
                      : null,
                ),
                ListTile(
                  onTap: () => changeCalendarLanguage(Language.english),
                  title: const Text('English'),
                  trailing: mmCalendarConfig.language == Language.english
                      ? const Icon(Icons.check_outlined, color: Colors.green)
                      : null,
                ),
                ListTile(
                  onTap: () => changeCalendarLanguage(Language.karen),
                  title: const Text('Karen'),
                  trailing: mmCalendarConfig.language == Language.karen
                      ? const Icon(Icons.check_outlined, color: Colors.green)
                      : null,
                ),
                ListTile(
                  onTap: () => changeCalendarLanguage(Language.mon),
                  title: const Text('Mon'),
                  trailing: mmCalendarConfig.language == Language.mon
                      ? const Icon(Icons.check_outlined, color: Colors.green)
                      : null,
                ),
                ListTile(
                  onTap: () => changeCalendarLanguage(Language.tai),
                  title: const Text('Tai'),
                  trailing: mmCalendarConfig.language == Language.tai
                      ? const Icon(Icons.check_outlined, color: Colors.green)
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final lang = switch (mmCalendarConfig.language) {
      Language.myanmar => 'Myanmar (Unicode)',
      Language.karen => 'Karen',
      Language.mon => 'Mon',
      Language.zawgyi => 'Myanmar (Zawgyi)',
      Language.tai => 'Tai',
      _ => 'English',
    };

    return ListTile(
      onTap: handleTap,
      leading: const Icon(IconlyLight.calendar),
      title: const Text('Calendar Language'),
      subtitle: Text(lang),
    );
  }
}

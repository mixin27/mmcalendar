import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mmcalendar/src/l10n/l10n.dart';

class AppLanguageListTile extends StatelessWidget {
  const AppLanguageListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    void handleTap() {
      showAdaptiveDialog(
        context: context,
        builder: (context) {
          return const LanguageChooserDialog();
        },
      );
    }

    final key = context.locale.countryCode == null
        ? 'locale_${context.locale.languageCode}'
        : 'locale_${context.locale.languageCode}_${context.locale.countryCode}';

    return ListTile(
      onTap: handleTap,
      leading: const Icon(Icons.language_outlined),
      title: const Text(LocaleKeys.language).tr(),
      subtitle: Text(key).tr(),
    );
  }
}

class LanguageChooserDialog extends StatelessWidget {
  const LanguageChooserDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocaleKeys.choose_language.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          L10n.all.length,
          (index) {
            final locale = L10n.all[index];

            final key = locale.countryCode == null
                ? 'locale_${locale.languageCode}'
                : 'locale_${locale.languageCode}_${locale.countryCode}';

            return ListTile(
              onTap: () {
                context.setLocale(locale);
                Navigator.of(context).pop();
              },
              title: Text(key).tr(),
              trailing: locale == context.locale
                  ? Icon(
                      Icons.check_outlined,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}

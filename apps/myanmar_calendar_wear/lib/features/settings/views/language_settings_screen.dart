import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_wear/settings/watch_settings.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:myanmar_calendar_wear/shared/watch_shape.dart';

/// Picks the calendar language. Interface words follow it: Myanmar for
/// Myanmar, English otherwise.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({
    required this.currentLanguage,
    required this.onLanguageChanged,
    super.key,
  });

  final Language currentLanguage;
  final ValueChanged<Language> onLanguageChanged;

  /// Each language in its own name, as people look for it.
  static String nameOf(Language language) => switch (language) {
    Language.myanmar => 'မြန်မာ',
    Language.english => 'English',
    Language.shan => 'ၽႃႇသႃႇတႆး',
    Language.mon => 'ဘာသာမန်',
    Language.karen => 'ကညီကျိာ်',
    Language.zawgyi => 'Zawgyi',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: WatchShape(
        builder: (context, shape, child) {
          final isRound = shape == WearShape.round;
          final edge = isRound ? 28.0 : 12.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(edge, isRound ? 28 : 12, edge, 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.language,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final language in WatchSettings.languages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LanguageTile(
                    name: nameOf(language),
                    selected: language == currentLanguage,
                    onTap: () {
                      onLanguageChanged(language);
                      Navigator.pop(context);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue.shade700.withValues(alpha: 0.5)
              : Colors.grey.shade900.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.blue.shade500
                : Colors.grey.shade700.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.blue.shade300,
                ),
              ),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? Colors.white : Colors.grey.shade300,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmcalendar/src/l10n/l10n.dart';
import 'package:mmcalendar/src/utils/shared_prefs/preference_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_switch_tile.g.dart';

const PreferenceKey keyTheme = 'key_theme';

class ThemeModeSwitchTile extends HookConsumerWidget {
  const ThemeModeSwitchTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

    final icon = switch (themeMode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      _ => Icons.brightness_4_outlined,
    };

    void changeTheme(ThemeMode mode) {
      ref.read(themeModeControllerProvider.notifier).setThemeMode(mode);
      Navigator.of(context).pop();
    }

    void handleTap() {
      showAdaptiveDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(LocaleKeys.theme).tr(),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () => changeTheme(ThemeMode.system),
                title: const Text(LocaleKeys.system_theme).tr(),
                trailing: themeMode == ThemeMode.system
                    ? const Icon(Icons.check_outlined, color: Colors.green)
                    : null,
              ),
              ListTile(
                onTap: () => changeTheme(ThemeMode.light),
                title: const Text(LocaleKeys.light_theme).tr(),
                trailing: themeMode == ThemeMode.light
                    ? const Icon(Icons.check_outlined, color: Colors.green)
                    : null,
              ),
              ListTile(
                onTap: () => changeTheme(ThemeMode.dark),
                title: const Text(LocaleKeys.dark_theme).tr(),
                trailing: themeMode == ThemeMode.dark
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
      leading: Icon(icon),
      title: const Text('Theme'),
      subtitle: const Text('Change theme mode.'),
    );
  }
}

@riverpod
class ThemeModeController extends _$ThemeModeController {
  ThemeMode _getCachedThemeMode() {
    final prefs = ref.read(preferenceManagerProvider);

    final mode = prefs.getData<String>(keyTheme);

    return switch (mode) {
      'ThemeMode.dark' => ThemeMode.dark,
      'ThemeMode.light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  @override
  ThemeMode build() {
    return _getCachedThemeMode();
  }

  void setThemeMode(ThemeMode mode) {
    final prefs = ref.read(preferenceManagerProvider);
    prefs.setData<String>(mode.toString(), keyTheme);

    state = _getCachedThemeMode();
  }
}

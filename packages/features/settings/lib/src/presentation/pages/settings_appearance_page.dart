import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/di/settings_injection.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../widgets/settings_widgets.dart';
import '../widgets/snackbar.dart';
import '../widgets/state_widgets.dart';

class SettingsAppearancePage extends StatefulWidget {
  const SettingsAppearancePage({super.key});

  @override
  State<SettingsAppearancePage> createState() => _SettingsAppearancePageState();
}

class _SettingsAppearancePageState extends State<SettingsAppearancePage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final AppIconPort _appIconPort = getIt<AppIconPort>();

  @override
  void initState() {
    _analyticsService.logScreenView(
      screenName: 'settings_apperance',
      screenClass: 'SettingsApperancePage',
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.palette_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.appearance ?? 'Appearance',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is SettingsInitial) {
            context.read<SettingsBloc>().add(const LoadSettings());
            return const LoadingView();
          }

          if (state is SettingsLoading) {
            return const LoadingView();
          }

          if (state is SettingsError) {
            return ErrorView(
              message: state.message,
              onRetry: () {
                context.read<SettingsBloc>().add(const LoadSettings());
              },
            );
          }

          if (state is SettingsLoaded) {
            return _buildContent(context, state.settings);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppSettingsEntity settings) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          SettingsTile(
            title: l10n?.themeMode ?? 'Theme Mode',
            subtitle: _getThemeModeText(settings.themeMode),
            leading: const Icon(Icons.brightness_6),
            onTap: () => _showThemeModeDialog(context, settings),
          ),
          SettingsTile(
            title: AppLocalizations.of(context)?.theme_preset ?? 'Theme Preset',
            subtitle: _getThemePresetName(settings.themePreset),
            leading: const Icon(Icons.color_lens),
            onTap: () => _showThemePresetDialog(context, settings),
          ),
          SettingsTile(
            title: 'App Icon',
            subtitle: _getAppIconName(settings.appIcon),
            leading: const Icon(Icons.apps_rounded),
            onTap: () => _showAppIconDialog(context, settings),
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, AppSettingsEntity settings) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedDialog(
        title: l10n?.themeMode ?? 'Theme Mode',
        icon: Icons.brightness_6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioOption<ThemeMode>(
              title: l10n?.light ?? 'Light',
              subtitle: l10n?.alwaysUseLightTheme ?? 'Always use light theme',
              icon: Icons.light_mode,
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (value) {
                context.read<SettingsBloc>().add(ChangeThemeMode(value!));
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<ThemeMode>(
              title: l10n?.dark ?? 'Dark',
              subtitle: l10n?.alwaysUseDarkTheme ?? 'Always use dark theme',
              icon: Icons.dark_mode,
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (value) {
                context.read<SettingsBloc>().add(ChangeThemeMode(value!));
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<ThemeMode>(
              title: l10n?.system ?? 'System',
              subtitle: l10n?.matchSystemTheme ?? 'Match system theme',
              icon: Icons.brightness_auto,
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (value) {
                context.read<SettingsBloc>().add(ChangeThemeMode(value!));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePresetDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedDialog(
        title: AppLocalizations.of(context)?.theme_preset ?? 'Theme Preset',
        icon: Icons.color_lens,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...ThemePresets.getAllPresets().map((preset) {
                return RadioOption<String>(
                  title: preset.name,
                  subtitle: '',
                  icon: Icons.palette,
                  value: preset.id,
                  groupValue: settings.themePreset,
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(ChangeThemePreset(value!));
                    Navigator.pop(dialogContext);
                  },
                );
              }),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),

              // Custom colors option
              CustomColorsOption(
                isSelected: settings.themePreset == 'custom',
                customColors: settings.customColors,
                onTap: () {
                  Navigator.pop(dialogContext);
                  showCustomColorsEditor(context, settings);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAppIconDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) async {
    final supported = await _appIconPort.isSupported();
    if (!context.mounted) return;
    if (!supported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App icon switching is not supported here.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentIconFromPlatform = await _appIconPort.getCurrentIcon();
    if (!context.mounted) return;
    final availableIconIds = _appIconPort.availableIcons
        .map((option) => option.id)
        .toSet();
    final currentIconId = availableIconIds.contains(currentIconFromPlatform)
        ? currentIconFromPlatform
        : 'default';

    if (currentIconId != settings.appIcon) {
      context.read<SettingsBloc>().add(ChangeAppIcon(currentIconId));
    }

    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedDialog(
        title: 'App Icon',
        icon: Icons.apps_rounded,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _appIconPort.availableIcons
                .map(
                  (option) => RadioOption<String>(
                    title: option.label,
                    subtitle: option.id == 'default'
                        ? 'Use standard app icon'
                        : 'Switch launcher icon',
                    icon: Icons.image_outlined,
                    value: option.id,
                    groupValue: currentIconId,
                    onChanged: (value) async {
                      final iconId = value ?? 'default';
                      Navigator.pop(dialogContext);

                      final applied = await _appIconPort.setIcon(iconId);
                      if (!context.mounted) return;
                      if (!applied) {
                        showErrorSnackBar(
                          context,
                          'Failed to switch app icon.',
                        );
                        return;
                      }

                      context.read<SettingsBloc>().add(ChangeAppIcon(iconId));
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _getThemeModeText(ThemeMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case ThemeMode.light:
        return l10n?.light ?? 'Light';
      case ThemeMode.dark:
        return l10n?.dark ?? 'Dark';
      default:
        return l10n?.system ?? 'System';
    }
  }

  String _getThemePresetName(String presetId) {
    if (presetId == "custom") return presetId.capitalize;
    return ThemePresets.getPreset(presetId).name;
  }

  String _getAppIconName(String iconId) {
    for (final option in _appIconPort.availableIcons) {
      if (option.id == iconId) {
        return option.label;
      }
    }
    return 'Default';
  }
}

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
              AppLocalizations.of(context)?.appearance ?? 'Apperance',
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
    return SingleChildScrollView(
      child: Column(
        children: [
          SettingsTile(
            title: 'Theme Mode',
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
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, AppSettingsEntity settings) {
    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedDialog(
        title: 'Theme Mode',
        icon: Icons.brightness_6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioOption<ThemeMode>(
              title: 'Light',
              subtitle: 'Always use light theme',
              icon: Icons.light_mode,
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (value) {
                context.read<SettingsBloc>().add(ChangeThemeMode(value!));
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<ThemeMode>(
              title: 'Dark',
              subtitle: 'Always use dark theme',
              icon: Icons.dark_mode,
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (value) {
                context.read<SettingsBloc>().add(ChangeThemeMode(value!));
                Navigator.pop(dialogContext);
              },
            ),
            RadioOption<ThemeMode>(
              title: 'System',
              subtitle: 'Match system theme',
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

  // Helper methods
  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System';
    }
  }

  String _getThemePresetName(String presetId) {
    if (presetId == "custom") return presetId.capitalize;
    return ThemePresets.getPreset(presetId).name;
  }
}

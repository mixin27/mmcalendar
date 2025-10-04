import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../../domain/entities/app_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            _showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is SettingsInitial) {
            context.read<SettingsBloc>().add(const LoadSettings());
            return const _LoadingView();
          }

          if (state is SettingsLoading) {
            return const _LoadingView();
          }

          if (state is SettingsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context.read<SettingsBloc>().add(const LoadSettings());
              },
            );
          }

          if (state is SettingsLoaded) {
            return _SettingsContent(settings: state.settings);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Loading View
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading settings...'),
        ],
      ),
    );
  }
}

/// Error View
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Settings',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings Content
class _SettingsContent extends StatelessWidget {
  final AppSettingsEntity settings;

  const _SettingsContent({required this.settings});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Modern App Bar
        SliverAppBar.large(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colorScheme.primaryContainer,
                    context.colorScheme.primaryContainer.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Settings Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Appearance Section
              _SettingsSection(
                title: 'Appearance',
                icon: Icons.palette,
                iconColor: colorScheme.primary,
                children: [
                  _SettingsTile(
                    title: 'Theme Mode',
                    subtitle: _getThemeModeText(settings.themeMode),
                    leading: const Icon(Icons.brightness_6),
                    onTap: () => _showThemeModeDialog(context, settings),
                  ),
                  _SettingsTile(
                    title: 'Theme Preset',
                    subtitle: _getThemePresetName(settings.themePreset),
                    leading: const Icon(Icons.color_lens),
                    onTap: () => _showThemePresetDialog(context, settings),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Language Section
              _SettingsSection(
                title: 'Language',
                icon: Icons.language,
                iconColor: colorScheme.secondary,
                children: [
                  _SettingsTile(
                    title: 'App Language',
                    subtitle: settings.appLanguage == 'en'
                        ? 'English'
                        : 'Myanmar',
                    leading: const Icon(Icons.translate),
                    onTap: () => _showAppLanguageDialog(context, settings),
                  ),
                  _SettingsTile(
                    title: 'Calendar Language',
                    subtitle: settings.calendarLanguage.name,
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _showCalendarLanguageDialog(context, settings),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Display Preferences Section
              _SettingsSection(
                title: 'Display Preferences',
                icon: Icons.visibility,
                iconColor: colorScheme.tertiary,
                children: [
                  _AnimatedSwitchTile(
                    title: 'Show Holidays',
                    subtitle: 'Display holiday indicators',
                    icon: Icons.celebration,
                    value: settings.showHolidays,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(
                        ToggleDisplayPreference(
                          StorageKeys.showHolidays,
                          value,
                        ),
                      );
                    },
                  ),
                  _AnimatedSwitchTile(
                    title: 'Show Astrology',
                    subtitle: 'Display astrological information',
                    icon: Icons.star,
                    value: settings.showAstrology,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(
                        ToggleDisplayPreference(
                          StorageKeys.showAstrology,
                          value,
                        ),
                      );
                    },
                  ),
                  _AnimatedSwitchTile(
                    title: 'Show Western Dates',
                    subtitle: 'Display Western calendar dates',
                    icon: Icons.event,
                    value: settings.showWesternDates,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(
                        ToggleDisplayPreference(
                          StorageKeys.showWesternDates,
                          value,
                        ),
                      );
                    },
                  ),
                  _AnimatedSwitchTile(
                    title: 'Show Myanmar Dates',
                    subtitle: 'Display Myanmar calendar dates',
                    icon: Icons.calendar_month,
                    value: settings.showMyanmarDates,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(
                        ToggleDisplayPreference(
                          StorageKeys.showMyanmarDates,
                          value,
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Calendar Configuration Section
              _SettingsSection(
                title: 'Calendar Configuration',
                icon: Icons.settings,
                iconColor: colorScheme.error,
                children: [
                  _SettingsTile(
                    title: 'Sasana Year Type',
                    subtitle: 'Type ${settings.calendarConfig.sasanaYearType}',
                    leading: const Icon(Icons.auto_awesome),
                    onTap: () => _showSasanaYearTypeDialog(context, settings),
                  ),
                  _SettingsTile(
                    title: 'Calendar Type',
                    subtitle: _getCalendarTypeName(
                      settings.calendarConfig.calendarType,
                    ),
                    leading: const Icon(Icons.event_note),
                    onTap: () => _showCalendarTypeDialog(context, settings),
                  ),
                  _SettingsTile(
                    title: 'Timezone Offset',
                    subtitle: '${settings.calendarConfig.timezoneOffset} hours',
                    leading: const Icon(Icons.access_time),
                    onTap: () => _showTimezoneDialog(context, settings),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // About Section
              _SettingsSection(
                title: 'About',
                icon: Icons.info_outline,
                iconColor: Colors.blue,
                children: [
                  ListTile(
                    leading: const Icon(Icons.apps),
                    title: const Text('App Name'),
                    subtitle: Text(AppConstants.appName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.tag),
                    title: const Text('App Version'),
                    subtitle: Text(AppConstants.appVersion),
                  ),
                  _SettingsTile(
                    title: 'Open Source Licenses',
                    subtitle: 'View all licenses',
                    leading: const Icon(Icons.description),
                    onTap: () => showLicensePage(context: context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Reset Button
              _ResetButton(),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
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
    return ThemePresets.getPreset(presetId).name;
  }

  String _getCalendarTypeName(int type) {
    switch (type) {
      case 0:
        return 'British';
      case 1:
        return 'Gregorian';
      case 2:
        return 'Julian';
      default:
        return 'Unknown';
    }
  }

  // Dialog methods
  void _showThemeModeDialog(BuildContext context, AppSettingsEntity settings) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EnhancedDialog(
        title: 'Theme Mode',
        icon: Icons.brightness_6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RadioOption<ThemeMode>(
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
            _RadioOption<ThemeMode>(
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
            _RadioOption<ThemeMode>(
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
      builder: (dialogContext) => _EnhancedDialog(
        title: 'Theme Preset',
        icon: Icons.color_lens,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemePresets.getAllPresets().map((preset) {
              return _RadioOption<String>(
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
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showAppLanguageDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EnhancedDialog(
        title: 'App Language',
        icon: Icons.translate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RadioOption<String>(
              title: 'English',
              subtitle: 'Display app in English',
              icon: Icons.language,
              value: 'en',
              groupValue: settings.appLanguage,
              onChanged: (value) {
                context.read<SettingsBloc>().add(ChangeAppLanguage(value!));
                Navigator.pop(dialogContext);
              },
            ),
            _RadioOption<String>(
              title: 'Myanmar',
              subtitle: 'Display app in Myanmar',
              icon: Icons.language,
              value: 'my',
              groupValue: settings.appLanguage,
              onChanged: (value) {
                context.read<SettingsBloc>().add(ChangeAppLanguage(value!));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCalendarLanguageDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EnhancedDialog(
        title: 'Calendar Language',
        icon: Icons.calendar_today,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: Language.values.map((language) {
              return _RadioOption<Language>(
                title: language.name,
                subtitle: 'Display calendar in ${language.name}',
                icon: Icons.calendar_month,
                value: language,
                groupValue: settings.calendarLanguage,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                    ChangeCalendarLanguage(value!),
                  );
                  Navigator.pop(dialogContext);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showSasanaYearTypeDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EnhancedDialog(
        title: 'Sasana Year Type',
        icon: Icons.auto_awesome,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RadioOption<int>(
              title: 'Type 0',
              subtitle: 'Default calculation method',
              icon: Icons.looks_one,
              value: 0,
              groupValue: settings.calendarConfig.sasanaYearType,
              onChanged: (value) => _updateCalendarConfig(
                context,
                settings,
                sasanaYearType: value,
              ),
            ),
            _RadioOption<int>(
              title: 'Type 1',
              subtitle: 'Alternative calculation method',
              icon: Icons.looks_two,
              value: 1,
              groupValue: settings.calendarConfig.sasanaYearType,
              onChanged: (value) => _updateCalendarConfig(
                context,
                settings,
                sasanaYearType: value,
              ),
            ),
            _RadioOption<int>(
              title: 'Type 2',
              subtitle: 'Alternative calculation method',
              icon: Icons.looks_3,
              value: 2,
              groupValue: settings.calendarConfig.sasanaYearType,
              onChanged: (value) => _updateCalendarConfig(
                context,
                settings,
                sasanaYearType: value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCalendarTypeDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EnhancedDialog(
        title: 'Calendar Type',
        icon: Icons.event_note,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RadioOption<int>(
              title: 'British',
              subtitle: 'British calendar system',
              icon: Icons.flag,
              value: 0,
              groupValue: settings.calendarConfig.calendarType,
              onChanged: (value) =>
                  _updateCalendarConfig(context, settings, calendarType: value),
            ),
            _RadioOption<int>(
              title: 'Gregorian',
              subtitle: 'Gregorian calendar system',
              icon: Icons.calendar_month,
              value: 1,
              groupValue: settings.calendarConfig.calendarType,
              onChanged: (value) =>
                  _updateCalendarConfig(context, settings, calendarType: value),
            ),
            _RadioOption<int>(
              title: 'Julian',
              subtitle: 'Julian calendar system',
              icon: Icons.calendar_today,
              value: 2,
              groupValue: settings.calendarConfig.calendarType,
              onChanged: (value) =>
                  _updateCalendarConfig(context, settings, calendarType: value),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimezoneDialog(BuildContext context, AppSettingsEntity settings) {
    final controller = TextEditingController(
      text: settings.calendarConfig.timezoneOffset.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.access_time),
        title: const Text('Timezone Offset'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Hours',
            hintText: '6.5',
            helperText: 'e.g., 6.5 for Myanmar Time (UTC+6:30)',
            prefixIcon: Icon(Icons.schedule),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                _updateCalendarConfig(context, settings, timezoneOffset: value);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateCalendarConfig(
    BuildContext context,
    AppSettingsEntity settings, {
    int? sasanaYearType,
    int? calendarType,
    double? timezoneOffset,
  }) {
    final newConfig = CalendarConfig(
      sasanaYearType: sasanaYearType ?? settings.calendarConfig.sasanaYearType,
      calendarType: calendarType ?? settings.calendarConfig.calendarType,
      gregorianStart: settings.calendarConfig.gregorianStart,
      timezoneOffset: timezoneOffset ?? settings.calendarConfig.timezoneOffset,
      defaultLanguage: settings.calendarConfig.defaultLanguage,
    );
    context.read<SettingsBloc>().add(UpdateCalendarConfiguration(newConfig));
    Navigator.pop(context);
  }
}

/// Settings Section Widget
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Settings Tile Widget
class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Animated Switch Tile
class _AnimatedSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AnimatedSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Enhanced Dialog Widget
class _EnhancedDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _EnhancedDialog({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(icon: Icon(icon), title: Text(title), content: child);
  }
}

/// Radio Option Widget
class _RadioOption<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const _RadioOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup(
      groupValue: groupValue,
      onChanged: onChanged,
      child: RadioListTile<T>(
        secondary: Icon(icon),
        title: Text(title),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        value: value,
      ),
    );
  }
}

/// Reset Button Widget
class _ResetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () => _showResetDialog(context),
        icon: const Icon(Icons.restore),
        label: const Text('Reset All Settings'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
        title: const Text('Reset Settings?'),
        content: const Text(
          'This will reset all settings to their default values. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<SettingsBloc>().add(const ResetAllSettings());
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

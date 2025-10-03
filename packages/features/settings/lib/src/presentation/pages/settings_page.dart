import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            context.showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          if (state is SettingsInitial) {
            context.read<SettingsBloc>().add(const LoadSettings());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: context.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading settings',
                    style: context.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(state.message, style: context.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<SettingsBloc>().add(const LoadSettings());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is SettingsLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance Section
                  SettingsSection(
                    title: 'Appearance',
                    children: [
                      SettingsTile(
                        title: 'Theme Mode',
                        subtitle: _getThemeModeText(state.settings.themeMode),
                        leading: const Icon(Icons.brightness_6),
                        onTap: () => _showThemeModeDialog(context, state),
                      ),
                      SettingsTile(
                        title: 'Theme Preset',
                        subtitle: _getThemePresetName(
                          state.settings.themePreset,
                        ),
                        leading: const Icon(Icons.palette),
                        onTap: () => _showThemePresetDialog(context, state),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Language Section
                  SettingsSection(
                    title: 'Language',
                    children: [
                      SettingsTile(
                        title: 'App Language',
                        subtitle: state.settings.appLanguage == 'en'
                            ? 'English'
                            : 'Myanmar',
                        leading: const Icon(Icons.language),
                        onTap: () => _showAppLanguageDialog(context, state),
                      ),
                      SettingsTile(
                        title: 'Calendar Language',
                        subtitle: state.settings.calendarLanguage.name,
                        leading: const Icon(Icons.calendar_today),
                        onTap: () =>
                            _showCalendarLanguageDialog(context, state),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Display Preferences Section
                  SettingsSection(
                    title: 'Display Preferences',
                    children: [
                      SwitchListTile(
                        title: const Text('Show Holidays'),
                        subtitle: const Text('Display holiday indicators'),
                        value: state.settings.showHolidays,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                            ToggleDisplayPreference(
                              StorageKeys.showHolidays,
                              value,
                            ),
                          );
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show Astrology'),
                        subtitle: const Text(
                          'Display astrological information',
                        ),
                        value: state.settings.showAstrology,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                            ToggleDisplayPreference(
                              StorageKeys.showAstrology,
                              value,
                            ),
                          );
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show Western Dates'),
                        subtitle: const Text('Display Western calendar dates'),
                        value: state.settings.showWesternDates,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                            ToggleDisplayPreference(
                              StorageKeys.showWesternDates,
                              value,
                            ),
                          );
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show Myanmar Dates'),
                        subtitle: const Text('Display Myanmar calendar dates'),
                        value: state.settings.showMyanmarDates,
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
                  SettingsSection(
                    title: 'Calendar Configuration',
                    children: [
                      SettingsTile(
                        title: 'Sasana Year Type',
                        subtitle:
                            'Type ${state.settings.calendarConfig.sasanaYearType}',
                        leading: const Icon(Icons.calendar_view_month),
                        onTap: () => _showSasanaYearTypeDialog(context, state),
                      ),
                      SettingsTile(
                        title: 'Calendar Type',
                        subtitle: _getCalendarTypeName(
                          state.settings.calendarConfig.calendarType,
                        ),
                        leading: const Icon(Icons.event_note),
                        onTap: () => _showCalendarTypeDialog(context, state),
                      ),
                      SettingsTile(
                        title: 'Timezone Offset',
                        subtitle:
                            '${state.settings.calendarConfig.timezoneOffset} hours',
                        leading: const Icon(Icons.access_time),
                        onTap: () => _showTimezoneDialog(context, state),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Advanced Section
                  SettingsSection(
                    title: 'Advanced',
                    children: [
                      SettingsTile(
                        title: 'Reset Settings',
                        subtitle: 'Restore default settings',
                        leading: Icon(
                          Icons.restore,
                          color: context.colorScheme.error,
                        ),
                        onTap: () => _showResetDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // App Information
                  SettingsSection(
                    title: 'About',
                    children: [
                      ListTile(
                        title: const Text('App Version'),
                        subtitle: Text(AppConstants.appVersion),
                        leading: const Icon(Icons.info_outline),
                      ),
                      ListTile(
                        title: const Text('App Name'),
                        subtitle: Text(AppConstants.appName),
                        leading: const Icon(Icons.apps),
                      ),
                      ListTile(
                        title: const Text('Licenses'),
                        subtitle: const Text('View open source licenses'),
                        leading: const Icon(Icons.description),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          showLicensePage(context: context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

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

  void _showThemeModeDialog(BuildContext context, SettingsLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Theme Mode'),
        content: RadioGroup<ThemeMode>(
          groupValue: state.settings.themeMode,
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(ChangeThemeMode(value));
              Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                value: ThemeMode.system,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePresetDialog(BuildContext context, SettingsLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Theme Preset'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemePresets.getAllPresets().map((preset) {
              return RadioGroup<String>(
                groupValue: state.settings.themePreset,
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsBloc>().add(ChangeThemePreset(value));
                    Navigator.pop(dialogContext);
                  }
                },
                child: RadioListTile<String>(
                  title: Text('${preset.icon ?? ''} ${preset.name}'),
                  value: preset.id,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showAppLanguageDialog(BuildContext context, SettingsLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('App Language'),
        content: RadioGroup<String>(
          groupValue: state.settings.appLanguage,
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(ChangeAppLanguage(value));
              Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(title: const Text('English'), value: 'en'),
              RadioListTile<String>(title: const Text('Myanmar'), value: 'my'),
            ],
          ),
        ),
      ),
    );
  }

  void _showCalendarLanguageDialog(BuildContext context, SettingsLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Calendar Language'),
        content: RadioGroup<Language>(
          groupValue: state.settings.calendarLanguage,
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(ChangeCalendarLanguage(value));
              Navigator.pop(dialogContext);
            }
          },
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: Language.values.map((language) {
                return RadioListTile<Language>(
                  title: Text(language.name),
                  value: language,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showSasanaYearTypeDialog(BuildContext context, SettingsLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sasana Year Type'),
        content: RadioGroup<int>(
          groupValue: state.settings.calendarConfig.sasanaYearType,
          onChanged: (value) {
            if (value != null) {
              final newConfig = CalendarConfig(
                sasanaYearType: value,
                calendarType: state.settings.calendarConfig.calendarType,
                gregorianStart: state.settings.calendarConfig.gregorianStart,
                timezoneOffset: state.settings.calendarConfig.timezoneOffset,
                defaultLanguage: state.settings.calendarConfig.defaultLanguage,
              );
              context.read<SettingsBloc>().add(
                UpdateCalendarConfiguration(newConfig),
              );
              Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<int>(title: const Text('Type 0'), value: 0),
              RadioListTile<int>(title: const Text('Type 1'), value: 1),
              RadioListTile<int>(title: const Text('Type 2'), value: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _showCalendarTypeDialog(BuildContext context, SettingsLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Calendar Type'),
        content: RadioGroup<int>(
          groupValue: state.settings.calendarConfig.calendarType,
          onChanged: (value) {
            if (value != null) {
              final newConfig = CalendarConfig(
                sasanaYearType: state.settings.calendarConfig.sasanaYearType,
                calendarType: value,
                gregorianStart: state.settings.calendarConfig.gregorianStart,
                timezoneOffset: state.settings.calendarConfig.timezoneOffset,
                defaultLanguage: state.settings.calendarConfig.defaultLanguage,
              );
              context.read<SettingsBloc>().add(
                UpdateCalendarConfiguration(newConfig),
              );
              Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<int>(title: const Text('British'), value: 0),
              RadioListTile<int>(title: const Text('Gregorian'), value: 1),
              RadioListTile<int>(title: const Text('Julian'), value: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimezoneDialog(BuildContext context, SettingsLoaded state) {
    final controller = TextEditingController(
      text: state.settings.calendarConfig.timezoneOffset.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Timezone Offset'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Hours (e.g., 6.5 for Myanmar)',
            hintText: '6.5',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                final newConfig = CalendarConfig(
                  sasanaYearType: state.settings.calendarConfig.sasanaYearType,
                  calendarType: state.settings.calendarConfig.calendarType,
                  gregorianStart: state.settings.calendarConfig.gregorianStart,
                  timezoneOffset: value,
                  defaultLanguage:
                      state.settings.calendarConfig.defaultLanguage,
                );
                context.read<SettingsBloc>().add(
                  UpdateCalendarConfiguration(newConfig),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to default? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SettingsBloc>().add(const ResetAllSettings());
              Navigator.pop(dialogContext);
              context.showSuccessSnackBar('Settings reset successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

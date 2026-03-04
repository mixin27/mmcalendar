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

const Map<String, String> _appIconPreviewAssets = <String, String>{
  'default': 'assets/branding/app_icon_1024.png',
  'moon': 'assets/branding/app_icon_moon_1024.png',
  'forest': 'assets/branding/app_icon_forest_1024.png',
  'minimal_flat': 'assets/branding/app_icon_minimal_flat_1024.png',
  'premium_dark': 'assets/branding/app_icon_premium_dark_1024.png',
  'traditional_myanmar':
      'assets/branding/app_icon_traditional_myanmar_1024.png',
};

class SettingsAppearancePage extends StatefulWidget {
  const SettingsAppearancePage({super.key});

  @override
  State<SettingsAppearancePage> createState() => _SettingsAppearancePageState();
}

class _SettingsAppearancePageState extends State<SettingsAppearancePage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  final AppIconPort _appIconPort = getIt<AppIconPort>();
  bool _isApplyingAppIcon = false;

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
            leading: _AppIconPreview(
              assetPath: _assetForIcon(settings.appIcon),
              iconSize: 22,
              borderRadius: 8,
            ),
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
    if (_isApplyingAppIcon) {
      showErrorSnackBar(context, 'Please wait, applying app icon...');
      return;
    }

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

    final selectedIconId = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var selected = currentIconId;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final mediaQuery = MediaQuery.of(sheetContext);
            final width = mediaQuery.size.width;
            final options = _appIconPort.availableIcons;
            final selectedOption = options.firstWhere(
              (option) => option.id == selected,
              orElse: () => options.first,
            );

            final crossAxisCount = width >= 900
                ? 4
                : width >= 680
                ? 3
                : 2;

            return Padding(
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: SizedBox(
                height: mediaQuery.size.height * 0.86,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                      child: Text(
                        'Choose App Icon',
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        'Select your preferred launcher icon style.',
                        style: Theme.of(sheetContext).textTheme.bodyMedium
                            ?.copyWith(
                              color: Theme.of(
                                sheetContext,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _SelectedIconPreviewCard(
                        option: selectedOption,
                        assetPath: _assetForIcon(selectedOption.id),
                        isCurrent: selectedOption.id == currentIconId,
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.86,
                        ),
                        itemCount: options.length,
                        itemBuilder: (gridContext, index) {
                          final option = options[index];
                          return _AppIconOptionCard(
                            option: option,
                            assetPath: _assetForIcon(option.id),
                            isSelected: option.id == selected,
                            isCurrent: option.id == currentIconId,
                            onTap: () {
                              setSheetState(() {
                                selected = option.id;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: selected == currentIconId
                                  ? null
                                  : () => Navigator.pop(sheetContext, selected),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!context.mounted || selectedIconId == null) {
      return;
    }
    if (selectedIconId == currentIconId) {
      return;
    }
    await _applyAppIcon(context, selectedIconId);
  }

  Future<void> _applyAppIcon(BuildContext context, String iconId) async {
    if (_isApplyingAppIcon) {
      return;
    }
    if (mounted) {
      setState(() {
        _isApplyingAppIcon = true;
      });
    }

    try {
      // Allow modal dismissal transition to finish before iOS icon request.
      await Future<void>.delayed(const Duration(milliseconds: 320));
      final applied = await _appIconPort.setIcon(iconId);
      if (!context.mounted) {
        return;
      }
      if (!applied) {
        showErrorSnackBar(context, 'Failed to switch app icon.');
        return;
      }
      context.read<SettingsBloc>().add(ChangeAppIcon(iconId));
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingAppIcon = false;
        });
      }
    }
  }

  String? _assetForIcon(String iconId) => _appIconPreviewAssets[iconId];

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

class _SelectedIconPreviewCard extends StatelessWidget {
  const _SelectedIconPreviewCard({
    required this.option,
    required this.assetPath,
    required this.isCurrent,
  });

  final AppIconOption option;
  final String? assetPath;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _AppIconPreview(assetPath: assetPath, iconSize: 56, borderRadius: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCurrent ? 'Current icon' : 'Tap Apply to use this icon',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Active',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppIconOptionCard extends StatelessWidget {
  const _AppIconOptionCard({
    required this.option,
    required this.assetPath,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
  });

  final AppIconOption option;
  final String? assetPath;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.06)
                : theme.colorScheme.surfaceContainerLow,
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Center(
                    child: _AppIconPreview(
                      assetPath: assetPath,
                      iconSize: 82,
                      borderRadius: 20,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: AnimatedScale(
                      scale: isSelected ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isCurrent
                    ? 'Current'
                    : (option.id == 'default'
                          ? 'Standard icon'
                          : 'Alternate icon'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppIconPreview extends StatelessWidget {
  const _AppIconPreview({
    required this.assetPath,
    required this.iconSize,
    required this.borderRadius,
  });

  final String? assetPath;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: assetPath == null
              ? Icon(
                  Icons.apps_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: iconSize * 0.42,
                )
              : Image(
                  image: ResizeImage(
                    AssetImage(assetPath!),
                    width: 260,
                    height: 260,
                  ),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.apps_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: iconSize * 0.42,
                  ),
                ),
        ),
      ),
    );
  }
}

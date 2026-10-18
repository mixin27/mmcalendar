import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:settings/settings.dart';
import 'package:settings/src/di/settings_injection.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../widgets/settings_widgets.dart';
import '../widgets/snackbar.dart';

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
    return SettingsSubPage(
      title: l10n?.appearance ?? 'Appearance',
      builder: (context, settings) => _groups(context, settings),
    );
  }

  List<Widget> _groups(BuildContext context, AppSettingsEntity settings) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SettingsBloc>();
    return [
      _AppStylePicker(
        value: settings.appStyle,
        onChanged: (style) => bloc.add(ChangeAppStyle(style)),
      ),
      _Labelled(
        label: l10n?.themeMode ?? 'Theme Mode',
        child: AppSegmented<ThemeMode>(
          segments: {
            ThemeMode.light: l10n?.light ?? 'Light',
            ThemeMode.dark: l10n?.dark ?? 'Dark',
            ThemeMode.system: l10n?.system ?? 'System',
          },
          value: settings.themeMode,
          onChanged: (mode) => bloc.add(ChangeThemeMode(mode)),
        ),
      ),
      AppGroup(
        label: l10n?.theme_preset ?? 'Theme Preset',
        children: [
          for (final preset in ThemePresets.getAllPresets())
            AppRow(
              leading: _Swatch(color: preset.lightColors.primary),
              title: preset.id == 'modern'
                  ? (l10n?.settingsThemePresetDefault(preset.name) ??
                        '${preset.name} (default)')
                  : preset.name,
              selected: settings.themePreset == preset.id,
              onTap: () => bloc.add(ChangeThemePreset(preset.id)),
            ),
          AppRow(
            leading:
                settings.themePreset == 'custom' &&
                    settings.customColors != null
                ? _Swatch(color: settings.customColors!.primary)
                : const Icon(Icons.colorize_outlined, size: 20),
            title: l10n?.settingsCustomColours ?? 'Custom colours…',
            selected: settings.themePreset == 'custom',
            chevron: true,
            onTap: () => showCustomColorsEditor(context, settings),
          ),
        ],
      ),
      AppGroup(
        children: [
          AppRow(
            leading: _AppIconPreview(
              assetPath: _assetForIcon(settings.appIcon),
              iconSize: 22,
              borderRadius: 7,
            ),
            title: l10n?.settingsAppIcon ?? 'App Icon',
            value: _getAppIconName(l10n, settings.appIcon),
            chevron: true,
            onTap: () => _showAppIconDialog(context, settings),
          ),
        ],
      ),
    ];
  }

  Future<void> _showAppIconDialog(
    BuildContext context,
    AppSettingsEntity settings,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (_isApplyingAppIcon) {
      showErrorSnackBar(
        context,
        l10n?.settingsAppIconApplying ?? 'Please wait, applying app icon...',
      );
      return;
    }

    final supported = await _appIconPort.isSupported();
    if (!context.mounted) return;
    if (!supported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.settingsAppIconUnsupported ??
                'App icon switching is not supported here.',
          ),
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

            final crossAxisCount = width >= ResponsiveUtils.desktopBreakpoint
                ? 4
                : width >= ResponsiveUtils.tabletBreakpoint
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
                        l10n?.settingsChooseAppIcon ?? 'Choose App Icon',
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        l10n?.settingsChooseAppIconSubtitle ??
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
                              child: Text(l10n?.cancel ?? 'Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: selected == currentIconId
                                  ? null
                                  : () => Navigator.pop(sheetContext, selected),
                              child: Text(l10n?.apply ?? 'Apply'),
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
      final l10n = AppLocalizations.of(context);
      if (!applied) {
        showErrorSnackBar(
          context,
          l10n?.settingsAppIconFailed ?? 'Failed to switch app icon.',
        );
        return;
      }
      context.read<SettingsBloc>().add(ChangeAppIcon(iconId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.settingsAppIconUpdated ?? 'App icon updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AppIconException catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error.message);
      }
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

  String _getAppIconName(AppLocalizations? l10n, String iconId) {
    for (final option in _appIconPort.availableIcons) {
      if (option.id == iconId) {
        return _appIconLabel(l10n, option);
      }
    }
    return l10n?.defaultLabel ?? 'Default';
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
    final l10n = AppLocalizations.of(context);
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
                  _appIconLabel(l10n, option),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCurrent
                      ? (l10n?.settingsAppIconCurrent ?? 'Current icon')
                      : (l10n?.settingsAppIconTapApply ??
                            'Tap Apply to use this icon'),
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
                l10n?.settingsAppIconActive ?? 'Active',
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
    final l10n = AppLocalizations.of(context);
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
                _appIconLabel(l10n, option),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isCurrent
                    ? (l10n?.settingsAppIconCurrentShort ?? 'Current')
                    : (option.id == 'default'
                          ? (l10n?.settingsAppIconStandard ?? 'Standard icon')
                          : (l10n?.settingsAppIconAlternate ??
                                'Alternate icon')),
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

/// Settings › Appearance › App style: Automatic, Clear or Material.
class _AppStylePicker extends StatelessWidget {
  const _AppStylePicker({required this.value, required this.onChanged});

  final AppStyle value;
  final ValueChanged<AppStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context);
    final clear = l10n?.settingsAppStyleClear ?? 'Clear';
    final material = l10n?.settingsAppStyleMaterial ?? 'Material';
    final automatic = AppStyle.automatic.resolve() == AppStyle.clear
        ? clear
        : material;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppGroupLabel(l10n?.settingsAppStyle ?? 'App style'),
        AppSegmented<AppStyle>(
          segments: {
            AppStyle.automatic: l10n?.settingsAppStyleAutomatic ?? 'Automatic',
            AppStyle.clear: clear,
            AppStyle.material: material,
          },
          value: value,
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Text(
            l10n?.settingsAppStyleFooter(automatic) ??
                'Automatic uses Material on Android and Clear on iPhone, iPad, '
                    'Mac and web (here: $automatic). Colours and content stay '
                    'the same; bars, lists and controls change.',
            style: TextStyle(fontSize: 12.5, color: t.secondaryLabel),
          ),
        ),
      ],
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [AppGroupLabel(label), child],
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: context.tokens.separator),
    ),
  );
}

/// An app icon's name in the app language, by its id.
String _appIconLabel(AppLocalizations? l10n, AppIconOption option) =>
    switch (option.id) {
      'default' => l10n?.defaultLabel,
      'moon' => l10n?.appIconMoon,
      'forest' => l10n?.appIconForest,
      'minimal_flat' => l10n?.appIconMinimalFlat,
      'premium_dark' => l10n?.appIconPremiumDark,
      'traditional_myanmar' => l10n?.appIconTraditionalMyanmar,
      _ => null,
    } ??
    option.label;

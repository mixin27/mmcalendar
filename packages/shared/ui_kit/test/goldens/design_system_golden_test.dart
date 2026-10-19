import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

/// One settings-like screen in each style and brightness: guards the
/// shapes, colours and spacing of the shared components.
Widget _screen(AppStyle style, Brightness brightness) {
  final theme = AppTheme.build(
    style: style,
    colorScheme: brightness == Brightness.dark
        ? AppColorSchemes.modernDark
        : AppColorSchemes.modernLight,
  );
  return Theme(
    data: theme,
    child: Builder(
      builder: (context) {
        final t = context.tokens;
        return Container(
          width: 360,
          color: t.background,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSegmented<int>(
                segments: const {0: 'Automatic', 1: 'Clear', 2: 'Material'},
                value: 0,
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              AppGroup(
                label: 'Display',
                footer: 'Changes apply to the grid and widgets.',
                children: [
                  AppRow.toggle(
                    title: 'Moon phases',
                    icon: Icons.nightlight_round,
                    iconColor: t.moon,
                    value: true,
                    onChanged: (_) {},
                  ),
                  AppRow(
                    title: 'Language',
                    icon: Icons.language,
                    value: 'Myanmar',
                    chevron: true,
                    onTap: () {},
                  ),
                  const AppRow(title: 'Light', selected: true),
                  const AppRow(
                    title: 'Reset all settings',
                    tone: AppRowTone.destructive,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  AppChip(label: 'All', selected: true, onSelected: (_) {}),
                  AppChip(label: 'Work', selected: false, onSelected: (_) {}),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(label: 'Save', onPressed: () {}),
              const SizedBox(height: 8),
              AppButton(
                label: 'Add reminder',
                kind: AppButtonKind.tinted,
                onPressed: () {},
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Delete',
                kind: AppButtonKind.destructive,
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              AppNavBar(
                destinations: const [
                  AppNavDestination(
                    icon: Icons.calendar_today_outlined,
                    selectedIcon: Icons.calendar_today,
                    label: 'Today',
                  ),
                  AppNavDestination(
                    icon: Icons.grid_view_outlined,
                    selectedIcon: Icons.grid_view_rounded,
                    label: 'Views',
                  ),
                  AppNavDestination(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: 'Settings',
                  ),
                ],
                selectedIndex: 0,
                onSelected: (_) {},
              ),
            ],
          ),
        );
      },
    ),
  );
}

void main() {
  goldenTest(
    'design system components in both styles',
    fileName: 'design_system_components',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: [
        for (final style in [AppStyle.clear, AppStyle.material])
          for (final brightness in Brightness.values)
            GoldenTestScenario(
              name: '${style.name} ${brightness.name}',
              child: _screen(style, brightness),
            ),
      ],
    ),
  );
}

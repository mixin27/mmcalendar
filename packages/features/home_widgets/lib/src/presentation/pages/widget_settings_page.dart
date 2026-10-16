import 'package:flutter/material.dart' hide WidgetState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../domain/entities/widget_config.dart';
import '../bloc/widget_bloc.dart';
import '../bloc/widget_event.dart';
import '../bloc/widget_state.dart';
import '../widgets/widget_add_instructions.dart';

class WidgetSettingsPage extends StatefulWidget {
  const WidgetSettingsPage({super.key});

  @override
  State<WidgetSettingsPage> createState() => _WidgetSettingsPageState();
}

class _WidgetSettingsPageState extends State<WidgetSettingsPage> {
  WidgetLoaded? _cachedLoadedState;

  void _updateConfig(BuildContext context, WidgetConfig config) =>
      context.read<WidgetBloc>().add(UpdateWidgetConfig(config));

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WidgetBloc, WidgetState>(
      listener: (context, state) {
        if (state is WidgetLoaded) _cachedLoadedState = state;
        if (state is WidgetError) {
          context.showToast(state.message, kind: AppToastKind.error);
        } else if (state is WidgetUpdated) {
          context.showToast(
            'Widget updated successfully!',
            kind: AppToastKind.success,
          );
        }
      },
      builder: (context, state) {
        final loaded = state is WidgetLoaded ? state : _cachedLoadedState;
        return AppPage(
          title: 'Widgets',
          previousTitle: 'Settings',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Widget',
              onPressed: () {
                context.read<WidgetBloc>().add(const RefreshWidget());
                context.showToast('Widget refresh started…');
              },
            ),
          ],
          children: loaded == null
              ? [
                  if (state is WidgetLoading)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ]
              : _groups(context, loaded),
        );
      },
    );
  }

  List<Widget> _groups(BuildContext context, WidgetLoaded state) {
    final t = context.tokens;
    final config = state.config;
    String yesNo(bool value) => value ? 'Yes' : 'No';
    return [
      if (!state.isActive) WidgetAddInstructions(),
      AppGroup(
        label: 'Status',
        children: [
          AppRow(
            icon: Icons.widgets_outlined,
            iconColor: state.isActive ? t.success : t.tertiaryLabel,
            title: 'Widget Active',
            value: yesNo(state.isActive),
          ),
          AppRow(
            icon: Icons.schedule,
            iconColor: state.isScheduled ? t.success : t.tertiaryLabel,
            title: 'Auto Updates',
            value: state.isScheduled ? 'On' : 'Off',
          ),
          if (state.currentData != null)
            AppRow(
              icon: Icons.update,
              iconColor: const Color(0xFF8E8E93),
              title: 'Last Updated',
              value: _formatDateTime(state.currentData!.lastUpdated),
            ),
        ],
      ),
      AppGroup(
        label: 'Widget Theme',
        children: [
          for (final theme in WidgetTheme.values)
            AppRow(
              title: _getThemeName(theme),
              subtitle: _getThemeDescription(theme),
              selected: config.theme == theme,
              onTap: () =>
                  _updateConfig(context, config.copyWith(theme: theme)),
            ),
        ],
      ),
      AppGroup(
        label: 'Display Options',
        children: [
          AppRow.toggle(
            title: 'Show Holidays',
            subtitle: 'Display public and religious holidays',
            value: config.showHolidays,
            onChanged: (v) =>
                _updateConfig(context, config.copyWith(showHolidays: v)),
          ),
          AppRow.toggle(
            title: 'Show Astrological Info',
            subtitle: 'Display sabbath, yatyaza, and pyathada',
            value: config.showAstrology,
            onChanged: (v) =>
                _updateConfig(context, config.copyWith(showAstrology: v)),
          ),
          AppRow(
            title: 'Widget Language',
            subtitle: 'Uses app calendar language automatically',
            value: _formatLanguageCode(config.language),
          ),
        ],
      ),
      AppGroup(
        footer: state.isScheduled
            ? 'Widgets refresh automatically each day.'
            : 'Enable auto updates to keep widgets current.',
        children: [
          if (!state.isScheduled)
            AppRow(
              title: 'Enable Auto Updates',
              tone: AppRowTone.accent,
              onTap: () {
                context.read<WidgetBloc>().add(const ScheduleWidgetUpdates());
                context.showToast(
                  'Auto updates enabled! Widgets will refresh every day.',
                  kind: AppToastKind.success,
                );
              },
            )
          else
            AppRow(
              title: 'Disable Auto Updates',
              tone: AppRowTone.destructive,
              onTap: () {
                context.read<WidgetBloc>().add(const CancelWidgetUpdates());
                context.showToast('Auto updates disabled');
              },
            ),
          AppRow(
            title: 'Refresh Widget Now',
            tone: AppRowTone.accent,
            onTap: () => context.read<WidgetBloc>().add(const RefreshWidget()),
          ),
          AppRow(
            title: 'Check Widget Status',
            tone: AppRowTone.accent,
            onTap: () {
              context.read<WidgetBloc>().add(const CheckWidgetStatus());
              context.showToast('Checking widget status…');
            },
          ),
        ],
      ),
    ];
  }

  String _formatLanguageCode(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'my':
        return 'Myanmar';
      case 'zawgyi':
        return 'Zawgyi';
      case 'mon':
        return 'Mon';
      case 'shan':
        return 'Shan';
      case 'karen':
        return 'Karen';
      default:
        return code.toUpperCase();
    }
  }

  String _getThemeName(WidgetTheme theme) {
    switch (theme) {
      case WidgetTheme.light:
        return 'Light';
      case WidgetTheme.dark:
        return 'Dark';
      case WidgetTheme.traditional:
        return 'Traditional Myanmar';
      case WidgetTheme.auto:
        return 'Auto (Default)';
      case WidgetTheme.gradientBlue:
        return 'Gradient Blue';
      case WidgetTheme.gradientPurple:
        return 'Gradient Purple';
      case WidgetTheme.gradientTeal:
        return 'Gradient Teal';
    }
  }

  String _getThemeDescription(WidgetTheme theme) {
    switch (theme) {
      case WidgetTheme.light:
        return 'Light background with dark text';
      case WidgetTheme.dark:
        return 'Dark background with light text';
      case WidgetTheme.traditional:
        return 'Myanmar traditional red and gold colors';
      case WidgetTheme.auto:
        return 'Follow built-in widget setting';
      case WidgetTheme.gradientBlue:
        return 'Gradient blue colors';
      case WidgetTheme.gradientPurple:
        return 'Gradient purple colors';
      case WidgetTheme.gradientTeal:
        return 'Gradient teal colors';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

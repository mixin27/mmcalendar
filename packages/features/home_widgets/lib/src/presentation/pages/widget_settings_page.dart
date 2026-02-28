import 'package:flutter/material.dart' hide WidgetState;
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Widget Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WidgetBloc>().add(const RefreshWidget());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Widget refresh started...')),
              );
            },
            tooltip: 'Refresh Widget',
          ),
        ],
      ),
      body: BlocConsumer<WidgetBloc, WidgetState>(
        listener: (context, state) {
          if (state is WidgetLoaded) {
            _cachedLoadedState = state;
          }

          if (state is WidgetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is WidgetUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Widget updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          final loadedState = state is WidgetLoaded
              ? state
              : _cachedLoadedState;

          if (loadedState == null && state is WidgetLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (loadedState == null) {
            return const SizedBox.shrink();
          }

          return _buildSettingsContent(context, loadedState);
        },
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, WidgetLoaded state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!state.isActive) WidgetAddInstructions(),
        _buildStatusSection(context, state),
        const SizedBox(height: 24),
        _buildThemeSection(context, state),
        const SizedBox(height: 24),
        _buildDisplayOptionsSection(context, state),
        const SizedBox(height: 24),
        _buildLanguageInfoSection(context, state),
        const SizedBox(height: 24),
        _buildActionsSection(context, state),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context, WidgetLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Widget Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Widget Active', state.isActive, Icons.widgets),
            const Divider(),
            _buildStatusRow(
              'Auto Updates Enabled',
              state.isScheduled,
              Icons.schedule,
            ),
            if (state.currentData != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('Last Updated'),
                subtitle: Text(_formatDateTime(state.currentData!.lastUpdated)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.green : Colors.grey),
      title: Text(label),
      trailing: Icon(
        isActive ? Icons.check_circle : Icons.cancel,
        color: isActive ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, WidgetLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Widget Theme',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...WidgetTheme.values.map((theme) {
              return RadioGroup(
                groupValue: state.config.theme,
                onChanged: (WidgetTheme? value) {
                  if (value != null) {
                    final newConfig = state.config.copyWith(theme: value);
                    context.read<WidgetBloc>().add(
                      UpdateWidgetConfig(newConfig),
                    );
                  }
                },
                child: RadioListTile<WidgetTheme>(
                  title: Text(_getThemeName(theme)),
                  subtitle: Text(_getThemeDescription(theme)),
                  value: theme,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayOptionsSection(BuildContext context, WidgetLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Show Holidays'),
              subtitle: const Text('Display public and religious holidays'),
              value: state.config.showHolidays,
              onChanged: (value) {
                final newConfig = state.config.copyWith(showHolidays: value);
                context.read<WidgetBloc>().add(UpdateWidgetConfig(newConfig));
              },
            ),
            SwitchListTile(
              title: const Text('Show Astrological Info'),
              subtitle: const Text('Display sabbath, yatyaza, and pyathada'),
              value: state.config.showAstrology,
              onChanged: (value) {
                final newConfig = state.config.copyWith(showAstrology: value);
                context.read<WidgetBloc>().add(UpdateWidgetConfig(newConfig));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageInfoSection(BuildContext context, WidgetLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.language_outlined),
          title: const Text('Widget Language'),
          subtitle: const Text('Uses app calendar language automatically'),
          trailing: Text(_formatLanguageCode(state.config.language)),
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!state.isScheduled)
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                label: const Text('Enable Auto Updates'),
                onPressed: () {
                  context.read<WidgetBloc>().add(const ScheduleWidgetUpdates());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Auto updates enabled! Widgets will refresh automatically every day.',
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule_send),
                label: const Text('Disable Auto Updates'),
                onPressed: () {
                  context.read<WidgetBloc>().add(const CancelWidgetUpdates());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Auto updates disabled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Widget Now'),
              onPressed: () {
                context.read<WidgetBloc>().add(const RefreshWidget());
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.info_outline),
              label: const Text('Check Widget Status'),
              onPressed: () {
                context.read<WidgetBloc>().add(const CheckWidgetStatus());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checking widget status...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.isScheduled
                          ? 'Widgets refresh automatically each day'
                          : 'Enable auto updates to keep widget current',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

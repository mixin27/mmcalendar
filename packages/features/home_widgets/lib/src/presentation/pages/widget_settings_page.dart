import 'package:flutter/material.dart' hide WidgetState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widgets/src/presentation/widgets/previews/compact_preview_widget.dart';
import 'package:home_widgets/src/presentation/widgets/previews/full_calendar_preview_widget.dart';
import 'package:home_widgets/src/presentation/widgets/previews/moon_phase_preview_widget.dart';
import 'package:home_widgets/src/presentation/widgets/previews/myanmar_month_preview_widget.dart';

import '../../domain/entities/widget_config.dart';
import '../bloc/widget_bloc.dart';
import '../bloc/widget_event.dart';
import '../bloc/widget_state.dart';
import '../widgets/widget_add_instructions.dart';

class WidgetSettingsPage extends StatelessWidget {
  const WidgetSettingsPage({super.key});

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
                const SnackBar(content: Text('Widget refreshed!')),
              );
            },
            tooltip: 'Refresh Widget',
          ),
        ],
      ),
      body: BlocConsumer<WidgetBloc, WidgetState>(
        listener: (context, state) {
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
          if (state is WidgetLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WidgetLoaded) {
            return _buildSettingsContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, WidgetLoaded state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!state.isActive) WidgetAddInstructions(),

        // Widget Preview
        Text('Widget Preview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Compact', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(
                width: double.infinity,
                height: 90,
                child: CompactPreviewWidget(),
              ),

              Text(
                'Full calendar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(
                width: double.infinity,
                height: 250,
                child: FullCalendarPreviewWidget(),
              ),
              Text(
                'Myanmar Month',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(
                width: double.infinity,
                height: 400,
                child: MyanmarMonthPreviewWidget(),
              ),
              Text(
                'Moon Phase',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(
                width: 220,
                height: 260,
                child: MoonPhasePreviewWidget(),
              ),
            ],
          ),
        ),

        // Card(
        //   elevation: 4,
        //   child: Padding(
        //     padding: const EdgeInsets.all(16),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text(
        //           'Widget Preview',
        //           style: Theme.of(context).textTheme.titleLarge,
        //         ),
        //         const SizedBox(height: 16),
        //         WidgetPreview(config: state.config, data: state.currentData),
        //       ],
        //     ),
        //   ),
        // ),
        const SizedBox(height: 24),

        // Widget Status
        _buildStatusSection(context, state),

        const SizedBox(height: 24),

        // Widget Size
        // _buildSizeSection(context, state),
        const SizedBox(height: 24),

        // Widget Theme
        _buildThemeSection(context, state),

        const SizedBox(height: 24),

        // Display Options
        // _buildDisplayOptionsSection(context, state),
        const SizedBox(height: 24),

        // Language
        _buildLanguageSection(context, state),

        const SizedBox(height: 24),

        // Actions
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

  // Widget _buildSizeSection(BuildContext context, WidgetLoaded state) {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Widget Size', style: Theme.of(context).textTheme.titleMedium),
  //           const SizedBox(height: 12),
  //           SegmentedButton<WidgetSize>(
  //             segments: const [
  //               ButtonSegment(
  //                 value: WidgetSize.small,
  //                 label: Text('Small'),
  //                 icon: Icon(Icons.crop_square),
  //               ),
  //               ButtonSegment(
  //                 value: WidgetSize.medium,
  //                 label: Text('Medium'),
  //                 icon: Icon(Icons.crop_16_9),
  //               ),
  //               ButtonSegment(
  //                 value: WidgetSize.large,
  //                 label: Text('Large'),
  //                 icon: Icon(Icons.crop_landscape),
  //               ),
  //             ],
  //             selected: {state.config.size},
  //             onSelectionChanged: (Set<WidgetSize> newSelection) {
  //               final newConfig = state.config.copyWith(
  //                 size: newSelection.first,
  //               );
  //               context.read<WidgetBloc>().add(UpdateWidgetConfig(newConfig));
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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

  // Widget _buildDisplayOptionsSection(BuildContext context, WidgetLoaded state) {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Display Options',
  //             style: Theme.of(context).textTheme.titleMedium,
  //           ),
  //           const SizedBox(height: 8),
  //           SwitchListTile(
  //             title: const Text('Show Myanmar Date'),
  //             subtitle: const Text('Display date in Myanmar calendar'),
  //             value: state.config.showMyanmarDate,
  //             onChanged: (bool value) {
  //               final newConfig = state.config.copyWith(showMyanmarDate: value);
  //               context.read<WidgetBloc>().add(UpdateWidgetConfig(newConfig));
  //             },
  //           ),
  //           SwitchListTile(
  //             title: const Text('Show Western Date'),
  //             subtitle: const Text('Display date in Western calendar'),
  //             value: state.config.showWesternDate,
  //             onChanged: (bool value) {
  //               final newConfig = state.config.copyWith(showWesternDate: value);
  //               context.read<WidgetBloc>().add(UpdateWidgetConfig(newConfig));
  //             },
  //           ),
  //           SwitchListTile(
  //             title: const Text('Show Holidays'),
  //             subtitle: const Text('Display public and religious holidays'),
  //             value: state.config.showHolidays,
  //             onChanged: (bool value) {
  //               final newConfig = state.config.copyWith(showHolidays: value);
  //               context.read<WidgetBloc>().add(UpdateWidgetConfig(newConfig));
  //             },
  //           ),
  //           SwitchListTile(
  //             title: const Text('Show Astrology'),
  //             subtitle: const Text('Display sabbath, yatyaza, and other info'),
  //             value: state.config.showAstrology,
  //             onChanged: (bool value) {
  //               final newConfig = state.config.copyWith(showAstrology: value);
  //               context.read<WidgetBloc>().add(UpdateWidgetConfig(newConfig));
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildLanguageSection(BuildContext context, WidgetLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RadioGroup<String>(
          groupValue: state.config.language,
          onChanged: (String? value) {
            if (value != null) {
              final newConfig = state.config.copyWith(language: value);
              context.read<WidgetBloc>().add(UpdateWidgetConfig(newConfig));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Widget Language',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              RadioListTile<String>(title: const Text('English'), value: 'en'),
              RadioListTile<String>(
                title: const Text('Myanmar (ဗမာ)'),
                value: 'my',
              ),
              RadioListTile<String>(
                title: const Text('Myanmar (Zawgyi)'),
                value: 'zawgyi',
              ),
              RadioListTile<String>(title: const Text('Mon'), value: 'mon'),
              RadioListTile<String>(
                title: const Text('Shan (Tai)'),
                value: 'shan',
              ),
              RadioListTile<String>(title: const Text('Karen'), value: 'karen'),
            ],
          ),
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

            // Schedule/Cancel Auto Updates Button
            if (!state.isScheduled)
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                label: const Text('Enable Auto Updates'),
                onPressed: () {
                  context.read<WidgetBloc>().add(const ScheduleWidgetUpdates());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Auto updates enabled! Widget will update daily at 12:01 AM',
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

            // Refresh Widget Now Button
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

            // Check Widget Status Button
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

            // Info Text
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
                          ? 'Widget updates automatically at 12:01 AM every day'
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../bloc/calendar_generation_bloc.dart';
import '../bloc/calendar_generation_event.dart';
import 'calendar_generation_ui_sections.dart';

class CalendarGeneralSettingsContent extends StatelessWidget {
  const CalendarGeneralSettingsContent({required this.request, super.key});

  final CalendarGenerationRequest request;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List<int>.generate(12, (index) => now.year - 5 + index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Generation Scope',
          description:
              'Choose whether to generate a single month or full year.',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<CalendarGenerationMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<CalendarGenerationMode>(
                  value: CalendarGenerationMode.month,
                  label: Text('Month'),
                  icon: Icon(Icons.calendar_view_month),
                ),
                ButtonSegment<CalendarGenerationMode>(
                  value: CalendarGenerationMode.year,
                  label: Text('Year'),
                  icon: Icon(Icons.calendar_view_day),
                ),
              ],
              selected: <CalendarGenerationMode>{request.mode},
              onSelectionChanged: (selection) {
                context.read<CalendarGenerationBloc>().add(
                  ChangeGenerationMode(selection.first),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        SettingsSection(
          title: 'Calendar & Period',
          description: 'Set calendar language and target month/year.',
          child: Column(
            children: [
              DropdownButtonFormField<Language>(
                initialValue: request.language,
                decoration: const InputDecoration(
                  labelText: 'Calendar Language',
                  border: OutlineInputBorder(),
                ),
                items: Language.values
                    .map(
                      (language) => DropdownMenuItem<Language>(
                        value: language,
                        child: Text(language.name.capitalize),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  context.read<CalendarGenerationBloc>().add(
                    ChangeGenerationLanguage(value),
                  );
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: request.year,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                items: years
                    .map(
                      (year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  context.read<CalendarGenerationBloc>().add(
                    ChangeGenerationYear(value),
                  );
                },
              ),
              if (request.mode == CalendarGenerationMode.month) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: request.month,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  items: List<int>.generate(12, (index) => index + 1)
                      .map(
                        (month) => DropdownMenuItem<int>(
                          value: month,
                          child: Text('$month'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    context.read<CalendarGenerationBloc>().add(
                      ChangeGenerationMonth(value),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

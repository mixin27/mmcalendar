import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../bloc/calendar_generation_bloc.dart';
import '../bloc/calendar_generation_event.dart';
import 'calendar_generation_ui_sections.dart';

class CalendarVisibilitySettingsContent extends StatelessWidget {
  const CalendarVisibilitySettingsContent({required this.request, super.key});

  final CalendarGenerationRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Date Cell Visibility',
          description: 'Choose which date details to display in cells.',
          child: Column(
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Holidays'),
                value: request.showHolidays,
                onChanged: (value) {
                  context.read<CalendarGenerationBloc>().add(
                    ToggleGenerationHolidays(value),
                  );
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Astrology'),
                value: request.showAstrology,
                onChanged: (value) {
                  context.read<CalendarGenerationBloc>().add(
                    ToggleGenerationAstrology(value),
                  );
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Western Dates'),
                value: request.showWesternDates,
                onChanged: (value) {
                  context.read<CalendarGenerationBloc>().add(
                    ToggleGenerationWesternDates(value),
                  );
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Myanmar Dates'),
                value: request.showMyanmarDates,
                onChanged: (value) {
                  context.read<CalendarGenerationBloc>().add(
                    ToggleGenerationMyanmarDates(value),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../bloc/calendar_generation_bloc.dart';
import '../bloc/calendar_generation_event.dart';
import 'calendar_generation_ui_sections.dart';

class CalendarThemeSettingsContent extends StatelessWidget {
  const CalendarThemeSettingsContent({
    required this.request,
    required this.presetColors,
    super.key,
  });

  final CalendarGenerationRequest request;
  final List<Color> presetColors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Color Theme',
          description: 'Define your calendar palette for text and accents.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColorSelector(
                label: 'Background',
                colors: presetColors,
                selectedValue: request.theme.backgroundColorValue,
                onColorSelected: (color) {
                  context.read<CalendarGenerationBloc>().add(
                    ChangeBackgroundColor(color.toARGB32()),
                  );
                },
              ),
              const SizedBox(height: 10),
              ColorSelector(
                label: 'Foreground',
                colors: presetColors,
                selectedValue: request.theme.foregroundColorValue,
                onColorSelected: (color) {
                  context.read<CalendarGenerationBloc>().add(
                    ChangeForegroundColor(color.toARGB32()),
                  );
                },
              ),
              const SizedBox(height: 10),
              ColorSelector(
                label: 'Accent',
                colors: presetColors,
                selectedValue: request.theme.accentColorValue,
                onColorSelected: (color) {
                  context.read<CalendarGenerationBloc>().add(
                    ChangeAccentColor(color.toARGB32()),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_landscape_decoration_area_side.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_paper_size.dart';
import '../bloc/calendar_generation_bloc.dart';
import '../bloc/calendar_generation_event.dart';
import 'calendar_generation_ui_sections.dart';

class CalendarLayoutSettingsContent extends StatelessWidget {
  const CalendarLayoutSettingsContent({required this.request, super.key});

  final CalendarGenerationRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: 'Page Setup',
          description: 'Configure canvas size and orientation.',
          child: Column(
            children: [
              DropdownButtonFormField<CalendarPaperSize>(
                initialValue: request.paperSize,
                decoration: const InputDecoration(
                  labelText: 'Paper Size',
                  border: OutlineInputBorder(),
                ),
                items: CalendarPaperSize.values
                    .map(
                      (paperSize) => DropdownMenuItem<CalendarPaperSize>(
                        value: paperSize,
                        child: Text(paperSize.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  context.read<CalendarGenerationBloc>().add(
                    ChangePaperSize(value),
                  );
                },
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<CalendarPageOrientation>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<CalendarPageOrientation>(
                      value: CalendarPageOrientation.portrait,
                      label: Text('Portrait'),
                      icon: Icon(Icons.stay_current_portrait),
                    ),
                    ButtonSegment<CalendarPageOrientation>(
                      value: CalendarPageOrientation.landscape,
                      label: Text('Landscape'),
                      icon: Icon(Icons.stay_current_landscape),
                    ),
                  ],
                  selected: <CalendarPageOrientation>{request.pageOrientation},
                  onSelectionChanged: (selection) {
                    context.read<CalendarGenerationBloc>().add(
                      ChangePageOrientation(selection.first),
                    );
                  },
                ),
              ),
              if (request.pageOrientation ==
                  CalendarPageOrientation.landscape) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Landscape custom area side',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<CalendarLandscapeDecorationAreaSide>(
                    showSelectedIcon: false,
                    segments: CalendarLandscapeDecorationAreaSide.values
                        .map(
                          (side) =>
                              ButtonSegment<
                                CalendarLandscapeDecorationAreaSide
                              >(value: side, label: Text(side.label)),
                        )
                        .toList(growable: false),
                    selected: <CalendarLandscapeDecorationAreaSide>{
                      request.landscapeDecorationAreaSide,
                    },
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) {
                        return;
                      }
                      context.read<CalendarGenerationBloc>().add(
                        ChangeLandscapeDecorationAreaSide(selection.first),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        SettingsSection(
          title: 'Output Quality',
          description: 'Higher quality gives sharper exports with larger size.',
          child: DropdownButtonFormField<CalendarImageQuality>(
            initialValue: request.imageQuality,
            decoration: const InputDecoration(
              labelText: 'Image Quality',
              border: OutlineInputBorder(),
            ),
            items: CalendarImageQuality.values
                .map(
                  (quality) => DropdownMenuItem<CalendarImageQuality>(
                    value: quality,
                    child: Text(quality.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              context.read<CalendarGenerationBloc>().add(
                ChangeImageQuality(value),
              );
            },
          ),
        ),
      ],
    );
  }
}

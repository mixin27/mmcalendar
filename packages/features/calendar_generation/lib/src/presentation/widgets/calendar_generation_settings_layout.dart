import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/calendar_export_tuning.dart';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<CalendarImageQuality>(
                initialValue: request.imageQuality,
                decoration: const InputDecoration(
                  labelText: 'Image Quality Preset',
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
              const SizedBox(height: 14),
              _ExportSliderRow(
                label: 'DPI',
                valueText: '${request.exportTuning.dpi}',
                min: CalendarExportTuning.minDpi.toDouble(),
                max: CalendarExportTuning.maxDpi.toDouble(),
                divisions:
                    (CalendarExportTuning.maxDpi -
                        CalendarExportTuning.minDpi) ~/
                    8,
                value: request.exportTuning.dpi.toDouble(),
                onChanged: (value) => context
                    .read<CalendarGenerationBloc>()
                    .add(ChangeExportDpi(value.round())),
              ),
              const SizedBox(height: 10),
              _ExportSliderRow(
                label: 'JPEG Quality',
                valueText: '${request.exportTuning.jpegQuality}',
                min: CalendarExportTuning.minJpegQuality.toDouble(),
                max: CalendarExportTuning.maxJpegQuality.toDouble(),
                divisions:
                    CalendarExportTuning.maxJpegQuality -
                    CalendarExportTuning.minJpegQuality,
                value: request.exportTuning.jpegQuality.toDouble(),
                onChanged: (value) => context
                    .read<CalendarGenerationBloc>()
                    .add(ChangeExportJpegQuality(value.round())),
              ),
              const SizedBox(height: 10),
              _ExportSliderRow(
                label: 'Target Size / page',
                valueText: '${request.exportTuning.targetSizeKb} KB',
                min: CalendarExportTuning.minTargetSizeKb.toDouble(),
                max: CalendarExportTuning.maxTargetSizeKb.toDouble(),
                divisions: 32,
                value: request.exportTuning.targetSizeKb.toDouble(),
                onChanged: request.exportTuning.enableAdaptiveCompression
                    ? (value) => context.read<CalendarGenerationBloc>().add(
                        ChangeExportTargetSizeKb(value.round()),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: request.exportTuning.enableAdaptiveCompression,
                title: const Text('Adaptive Compression'),
                subtitle: const Text(
                  'Automatically reduce file size to fit target size.',
                ),
                onChanged: (value) {
                  context.read<CalendarGenerationBloc>().add(
                    ToggleAdaptiveImageCompression(value),
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

class _ExportSliderRow extends StatelessWidget {
  const _ExportSliderRow({
    required this.label,
    required this.valueText,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    final titleColor = disabled
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: titleColor),
            ),
            const Spacer(),
            Text(
              valueText,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: titleColor),
            ),
          ],
        ),
        Slider(
          min: min,
          max: max,
          divisions: divisions,
          value: value.clamp(min, max),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/calendar_export_tuning.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_landscape_decoration_area_side.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_paper_size.dart';
import '../../domain/entities/calendar_preview_theme.dart';
import '../bloc/calendar_generation_bloc.dart';
import '../bloc/calendar_generation_event.dart';
import 'calendar_generation_ui_sections.dart';

class CalendarLayoutSettingsContent extends StatefulWidget {
  const CalendarLayoutSettingsContent({required this.request, super.key});

  final CalendarGenerationRequest request;

  @override
  State<CalendarLayoutSettingsContent> createState() =>
      _CalendarLayoutSettingsContentState();
}

class _CalendarLayoutSettingsContentState
    extends State<CalendarLayoutSettingsContent> {
  int _selectedFreeBoxIndex = 0;

  @override
  void didUpdateWidget(covariant CalendarLayoutSettingsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxIndex = widget.request.theme.freeSpaceBoxes.length - 1;
    if (maxIndex < 0) {
      _selectedFreeBoxIndex = 0;
      return;
    }
    if (_selectedFreeBoxIndex > maxIndex) {
      _selectedFreeBoxIndex = maxIndex;
    }
  }

  void _updateTheme(CalendarPreviewTheme theme) {
    context.read<CalendarGenerationBloc>().add(
      UpdateCalendarPreviewTheme(theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final theme = request.theme;
    final freeSpaceBoxes = theme.freeSpaceBoxes;
    final hasBoxes = freeSpaceBoxes.isNotEmpty;
    final selectedBoxIndex = hasBoxes
        ? _selectedFreeBoxIndex.clamp(0, freeSpaceBoxes.length - 1)
        : 0;
    final selectedBox = hasBoxes ? freeSpaceBoxes[selectedBoxIndex] : null;

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
          title: 'Calendar Layout',
          description:
              'Move main calendar content, add/remove free-space boxes and customize borders.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendar Content Position',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              _ExportSliderRow(
                label: 'Offset X',
                valueText: theme.calendarContentOffsetX.toStringAsFixed(2),
                min: -1.0,
                max: 1.0,
                divisions: 200,
                value: theme.calendarContentOffsetX,
                onChanged: (value) =>
                    _updateTheme(theme.copyWith(calendarContentOffsetX: value)),
              ),
              _ExportSliderRow(
                label: 'Offset Y',
                valueText: theme.calendarContentOffsetY.toStringAsFixed(2),
                min: -1.0,
                max: 1.0,
                divisions: 200,
                value: theme.calendarContentOffsetY,
                onChanged: (value) =>
                    _updateTheme(theme.copyWith(calendarContentOffsetY: value)),
              ),
              _ExportSliderRow(
                label: 'Content Width',
                valueText:
                    '${(theme.calendarContentWidthFactor * 100).round()}%',
                min: 0.4,
                max: 1.0,
                divisions: 60,
                value: theme.calendarContentWidthFactor,
                onChanged: (value) => _updateTheme(
                  theme.copyWith(calendarContentWidthFactor: value),
                ),
              ),
              _ExportSliderRow(
                label: 'Content Height',
                valueText:
                    '${(theme.calendarContentHeightFactor * 100).round()}%',
                min: 0.4,
                max: 1.0,
                divisions: 60,
                value: theme.calendarContentHeightFactor,
                onChanged: (value) => _updateTheme(
                  theme.copyWith(calendarContentHeightFactor: value),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Typography Scale',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              _ExportSliderRow(
                label: 'Month/Year Label',
                valueText: '${(theme.monthYearFontScale * 100).round()}%',
                min: 0.7,
                max: 1.8,
                divisions: 55,
                value: theme.monthYearFontScale,
                onChanged: (value) =>
                    _updateTheme(theme.copyWith(monthYearFontScale: value)),
              ),
              _ExportSliderRow(
                label: 'Weekday Label',
                valueText: '${(theme.weekdayFontScale * 100).round()}%',
                min: 0.7,
                max: 1.8,
                divisions: 55,
                value: theme.weekdayFontScale,
                onChanged: (value) =>
                    _updateTheme(theme.copyWith(weekdayFontScale: value)),
              ),
              const SizedBox(height: 8),
              Text(
                'Date Grid Border',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<CalendarBorderDesign>(
                initialValue: theme.gridBorderDesign,
                decoration: const InputDecoration(
                  labelText: 'Grid Border Design',
                  border: OutlineInputBorder(),
                ),
                items: CalendarBorderDesign.values
                    .map(
                      (design) => DropdownMenuItem<CalendarBorderDesign>(
                        value: design,
                        child: Text(design.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  _updateTheme(theme.copyWith(gridBorderDesign: value));
                },
              ),
              const SizedBox(height: 6),
              _ExportSliderRow(
                label: 'Grid Border Width',
                valueText: theme.gridBorderWidth.toStringAsFixed(1),
                min: 0.1,
                max: 4.0,
                divisions: 39,
                value: theme.gridBorderWidth,
                onChanged: (value) =>
                    _updateTheme(theme.copyWith(gridBorderWidth: value)),
              ),
              _ExportSliderRow(
                label: 'Grid Corner Radius',
                valueText: theme.gridCornerRadius.toStringAsFixed(1),
                min: 0.0,
                max: 20.0,
                divisions: 40,
                value: theme.gridCornerRadius,
                onChanged: (value) =>
                    _updateTheme(theme.copyWith(gridCornerRadius: value)),
              ),
              const SizedBox(height: 8),
              Text(
                'Free Space Boxes',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        final id =
                            'box_${DateTime.now().microsecondsSinceEpoch}';
                        final nextBoxes = <CalendarFreeSpaceBox>[
                          ...freeSpaceBoxes,
                          CalendarFreeSpaceBox(
                            id: id,
                            x: 0.05,
                            y: 0.05,
                            width: 0.9,
                            height: 0.4,
                            fillColorValue: 0x80FFFFFF,
                            borderColorValue: 0x401E293B,
                            borderWidth: 1.0,
                            cornerRadius: 6,
                            borderDesign: CalendarBorderDesign.soft,
                            visible: true,
                          ),
                        ];
                        _updateTheme(theme.copyWith(freeSpaceBoxes: nextBoxes));
                        setState(
                          () => _selectedFreeBoxIndex = nextBoxes.length - 1,
                        );
                      },
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Add Box'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: hasBoxes
                          ? () {
                              final nextBoxes = List<CalendarFreeSpaceBox>.of(
                                freeSpaceBoxes,
                              )..removeAt(selectedBoxIndex);
                              _updateTheme(
                                theme.copyWith(freeSpaceBoxes: nextBoxes),
                              );
                              setState(() {
                                if (nextBoxes.isEmpty) {
                                  _selectedFreeBoxIndex = 0;
                                } else if (_selectedFreeBoxIndex >=
                                    nextBoxes.length) {
                                  _selectedFreeBoxIndex = nextBoxes.length - 1;
                                }
                              });
                            }
                          : null,
                      icon: const Icon(Icons.indeterminate_check_box_outlined),
                      label: const Text('Remove'),
                    ),
                  ),
                ],
              ),
              if (hasBoxes) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: selectedBoxIndex,
                  decoration: const InputDecoration(
                    labelText: 'Selected Box',
                    border: OutlineInputBorder(),
                  ),
                  items: List<DropdownMenuItem<int>>.generate(
                    freeSpaceBoxes.length,
                    (index) => DropdownMenuItem<int>(
                      value: index,
                      child: Text('Box ${index + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedFreeBoxIndex = value);
                  },
                ),
                const SizedBox(height: 6),
                _ExportSliderRow(
                  label: 'Box X',
                  valueText: selectedBox!.x.toStringAsFixed(2),
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  value: selectedBox.x,
                  onChanged: (value) {
                    final next = selectedBox.copyWith(x: value);
                    final boxes = List<CalendarFreeSpaceBox>.of(freeSpaceBoxes);
                    boxes[selectedBoxIndex] = next;
                    _updateTheme(theme.copyWith(freeSpaceBoxes: boxes));
                  },
                ),
                _ExportSliderRow(
                  label: 'Box Y',
                  valueText: selectedBox.y.toStringAsFixed(2),
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  value: selectedBox.y,
                  onChanged: (value) {
                    final next = selectedBox.copyWith(y: value);
                    final boxes = List<CalendarFreeSpaceBox>.of(freeSpaceBoxes);
                    boxes[selectedBoxIndex] = next;
                    _updateTheme(theme.copyWith(freeSpaceBoxes: boxes));
                  },
                ),
                _ExportSliderRow(
                  label: 'Box Width',
                  valueText: selectedBox.width.toStringAsFixed(2),
                  min: 0.05,
                  max: 1.0,
                  divisions: 95,
                  value: selectedBox.width,
                  onChanged: (value) {
                    final next = selectedBox.copyWith(width: value);
                    final boxes = List<CalendarFreeSpaceBox>.of(freeSpaceBoxes);
                    boxes[selectedBoxIndex] = next;
                    _updateTheme(theme.copyWith(freeSpaceBoxes: boxes));
                  },
                ),
                _ExportSliderRow(
                  label: 'Box Height',
                  valueText: selectedBox.height.toStringAsFixed(2),
                  min: 0.05,
                  max: 1.0,
                  divisions: 95,
                  value: selectedBox.height,
                  onChanged: (value) {
                    final next = selectedBox.copyWith(height: value);
                    final boxes = List<CalendarFreeSpaceBox>.of(freeSpaceBoxes);
                    boxes[selectedBoxIndex] = next;
                    _updateTheme(theme.copyWith(freeSpaceBoxes: boxes));
                  },
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<CalendarBorderDesign>(
                  initialValue: selectedBox.borderDesign,
                  decoration: const InputDecoration(
                    labelText: 'Box Border Design',
                    border: OutlineInputBorder(),
                  ),
                  items: CalendarBorderDesign.values
                      .map(
                        (design) => DropdownMenuItem<CalendarBorderDesign>(
                          value: design,
                          child: Text(design.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    final next = selectedBox.copyWith(borderDesign: value);
                    final boxes = List<CalendarFreeSpaceBox>.of(freeSpaceBoxes);
                    boxes[selectedBoxIndex] = next;
                    _updateTheme(theme.copyWith(freeSpaceBoxes: boxes));
                  },
                ),
                const SizedBox(height: 6),
                _ExportSliderRow(
                  label: 'Box Border Width',
                  valueText: selectedBox.borderWidth.toStringAsFixed(1),
                  min: 0.0,
                  max: 6.0,
                  divisions: 60,
                  value: selectedBox.borderWidth,
                  onChanged: (value) {
                    final next = selectedBox.copyWith(borderWidth: value);
                    final boxes = List<CalendarFreeSpaceBox>.of(freeSpaceBoxes);
                    boxes[selectedBoxIndex] = next;
                    _updateTheme(theme.copyWith(freeSpaceBoxes: boxes));
                  },
                ),
                _ExportSliderRow(
                  label: 'Box Corner Radius',
                  valueText: selectedBox.cornerRadius.toStringAsFixed(1),
                  min: 0.0,
                  max: 32.0,
                  divisions: 64,
                  value: selectedBox.cornerRadius,
                  onChanged: (value) {
                    final next = selectedBox.copyWith(cornerRadius: value);
                    final boxes = List<CalendarFreeSpaceBox>.of(freeSpaceBoxes);
                    boxes[selectedBoxIndex] = next;
                    _updateTheme(theme.copyWith(freeSpaceBoxes: boxes));
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: selectedBox.visible,
                  title: const Text('Show Selected Box'),
                  onChanged: (value) {
                    final next = selectedBox.copyWith(visible: value);
                    final boxes = List<CalendarFreeSpaceBox>.of(freeSpaceBoxes);
                    boxes[selectedBoxIndex] = next;
                    _updateTheme(theme.copyWith(freeSpaceBoxes: boxes));
                  },
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

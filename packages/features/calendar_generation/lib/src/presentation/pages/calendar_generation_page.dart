import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_core/shared_core.dart';

import '../../di/calendar_generation_injection.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_paper_size.dart';
import '../../domain/entities/generation_artifact.dart';
import '../../rendering/export/calendar_export_service.dart';
import '../bloc/calendar_generation_bloc.dart';
import '../bloc/calendar_generation_event.dart';
import '../bloc/calendar_generation_state.dart';
import '../widgets/calendar_generation_preview_page.dart';

class CalendarGenerationPage extends StatelessWidget {
  const CalendarGenerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CalendarGenerationBloc>(
      create: (_) =>
          getIt<CalendarGenerationBloc>()
            ..add(const InitializeCalendarGeneration()),
      child: const _CalendarGenerationView(),
    );
  }
}

class _CalendarGenerationView extends StatefulWidget {
  const _CalendarGenerationView();

  @override
  State<_CalendarGenerationView> createState() =>
      _CalendarGenerationViewState();
}

class _CalendarGenerationViewState extends State<_CalendarGenerationView> {
  final TextEditingController _imageUrlController = TextEditingController();
  int _previewPage = 0;
  bool _isProcessingAction = false;
  String? _processingLabel;

  static const List<Color> _presetColors = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
    Color(0xFFFDF6E3),
    Color(0xFF0F172A),
    Color(0xFF111827),
    Color(0xFF14532D),
    Color(0xFF1E293B),
    Color(0xFF7C2D12),
    Color(0xFF4C1D95),
  ];

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Generation'),
        actions: [
          IconButton(
            onPressed: _isProcessingAction ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
          ),
          IconButton(
            onPressed: _isProcessingAction ? null : _exportImages,
            icon: const Icon(Icons.image_outlined),
            tooltip: 'Export Image',
          ),
          IconButton(
            onPressed: _isProcessingAction ? null : _printPdf,
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
          ),
        ],
      ),
      body: Stack(
        children: [
          BlocBuilder<CalendarGenerationBloc, CalendarGenerationState>(
            builder: (context, state) {
              if (state is CalendarGenerationInitial ||
                  state is CalendarGenerationLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CalendarGenerationError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 12),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            context.read<CalendarGenerationBloc>().add(
                              const InitializeCalendarGeneration(),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final loadedState = state as CalendarGenerationLoaded;
              final request = loadedState.request;
              final pages = loadedState.pages;

              if (_imageUrlController.text !=
                  (request.theme.backgroundImageUrl ?? '')) {
                _imageUrlController.text =
                    request.theme.backgroundImageUrl ?? '';
              }

              final now = DateTime.now();
              final years = List<int>.generate(
                12,
                (index) => now.year - 5 + index,
              );

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SegmentedButton<CalendarGenerationMode>(
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
                                selected: <CalendarGenerationMode>{
                                  request.mode,
                                },
                                onSelectionChanged: (selection) {
                                  context.read<CalendarGenerationBloc>().add(
                                    ChangeGenerationMode(selection.first),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
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
                                        context
                                            .read<CalendarGenerationBloc>()
                                            .add(ChangeGenerationYear(value));
                                      },
                                    ),
                                  ),
                                  if (request.mode ==
                                      CalendarGenerationMode.month) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        initialValue: request.month,
                                        decoration: const InputDecoration(
                                          labelText: 'Month',
                                          border: OutlineInputBorder(),
                                        ),
                                        items:
                                            List<int>.generate(12, (i) => i + 1)
                                                .map(
                                                  (month) =>
                                                      DropdownMenuItem<int>(
                                                        value: month,
                                                        child: Text('$month'),
                                                      ),
                                                )
                                                .toList(growable: false),
                                        onChanged: (value) {
                                          if (value == null) {
                                            return;
                                          }
                                          context
                                              .read<CalendarGenerationBloc>()
                                              .add(
                                                ChangeGenerationMonth(value),
                                              );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        DropdownButtonFormField<
                                          CalendarPaperSize
                                        >(
                                          initialValue: request.paperSize,
                                          decoration: const InputDecoration(
                                            labelText: 'Paper Size',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: CalendarPaperSize.values
                                              .map(
                                                (paperSize) =>
                                                    DropdownMenuItem<
                                                      CalendarPaperSize
                                                    >(
                                                      value: paperSize,
                                                      child: Text(
                                                        paperSize.label,
                                                      ),
                                                    ),
                                              )
                                              .toList(growable: false),
                                          onChanged: (value) {
                                            if (value == null) {
                                              return;
                                            }
                                            context
                                                .read<CalendarGenerationBloc>()
                                                .add(ChangePaperSize(value));
                                          },
                                        ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child:
                                        DropdownButtonFormField<
                                          CalendarImageQuality
                                        >(
                                          initialValue: request.imageQuality,
                                          decoration: const InputDecoration(
                                            labelText: 'Image Quality',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: CalendarImageQuality.values
                                              .map(
                                                (quality) =>
                                                    DropdownMenuItem<
                                                      CalendarImageQuality
                                                    >(
                                                      value: quality,
                                                      child: Text(
                                                        quality.label,
                                                      ),
                                                    ),
                                              )
                                              .toList(growable: false),
                                          onChanged: (value) {
                                            if (value == null) {
                                              return;
                                            }
                                            context
                                                .read<CalendarGenerationBloc>()
                                                .add(ChangeImageQuality(value));
                                          },
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SegmentedButton<CalendarPageOrientation>(
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
                                selected: <CalendarPageOrientation>{
                                  request.pageOrientation,
                                },
                                onSelectionChanged: (selection) {
                                  context.read<CalendarGenerationBloc>().add(
                                    ChangePageOrientation(selection.first),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilterChip(
                                    label: const Text('Holidays'),
                                    selected: request.showHolidays,
                                    onSelected: (value) {
                                      context
                                          .read<CalendarGenerationBloc>()
                                          .add(ToggleGenerationHolidays(value));
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Astrology'),
                                    selected: request.showAstrology,
                                    onSelected: (value) {
                                      context
                                          .read<CalendarGenerationBloc>()
                                          .add(
                                            ToggleGenerationAstrology(value),
                                          );
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Western Dates'),
                                    selected: request.showWesternDates,
                                    onSelected: (value) {
                                      context
                                          .read<CalendarGenerationBloc>()
                                          .add(
                                            ToggleGenerationWesternDates(value),
                                          );
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Myanmar Dates'),
                                    selected: request.showMyanmarDates,
                                    onSelected: (value) {
                                      context
                                          .read<CalendarGenerationBloc>()
                                          .add(
                                            ToggleGenerationMyanmarDates(value),
                                          );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _ColorSelector(
                                label: 'Background',
                                colors: _presetColors,
                                selectedValue:
                                    request.theme.backgroundColorValue,
                                onColorSelected: (color) {
                                  context.read<CalendarGenerationBloc>().add(
                                    ChangeBackgroundColor(color.toARGB32()),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _ColorSelector(
                                label: 'Foreground',
                                colors: _presetColors,
                                selectedValue:
                                    request.theme.foregroundColorValue,
                                onColorSelected: (color) {
                                  context.read<CalendarGenerationBloc>().add(
                                    ChangeForegroundColor(color.toARGB32()),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _ColorSelector(
                                label: 'Accent',
                                colors: _presetColors,
                                selectedValue: request.theme.accentColorValue,
                                onColorSelected: (color) {
                                  context.read<CalendarGenerationBloc>().add(
                                    ChangeAccentColor(color.toARGB32()),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _imageUrlController,
                                decoration: InputDecoration(
                                  labelText: 'Background Image URL (optional)',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () {
                                      context
                                          .read<CalendarGenerationBloc>()
                                          .add(
                                            ChangeBackgroundImageUrl(
                                              _imageUrlController.text.trim(),
                                            ),
                                          );
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            request.mode == CalendarGenerationMode.month
                                ? 'Month Preview'
                                : 'Year Preview (${pages.length} pages)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(
                          height: 690,
                          child: PageView.builder(
                            itemCount: pages.length,
                            onPageChanged: (index) {
                              setState(() => _previewPage = index);
                            },
                            itemBuilder: (context, index) {
                              return CalendarGenerationPreviewPage(
                                model: pages[index],
                                request: request,
                              );
                            },
                          ),
                        ),
                        if (pages.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Center(
                              child: Text(
                                'Page ${_previewPage + 1} / ${pages.length}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (_isProcessingAction)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.2),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                          const SizedBox(width: 12),
                          Text(_processingLabel ?? 'Processing...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    await _runGenerationAction(
      actionLabel: 'Generating PDF',
      onRun: (state) async {
        final artifact = await getIt<CalendarExportService>().buildPdf(
          request: state.request,
          pages: state.pages,
        );
        await _shareArtifacts([artifact], title: 'Calendar PDF');
        if (!mounted) {
          return;
        }
        _showSnack('PDF ready: ${artifact.fileName}');
      },
    );
  }

  Future<void> _exportImages() async {
    await _runGenerationAction(
      actionLabel: 'Generating images',
      onRun: (state) async {
        final exportService = getIt<CalendarExportService>();
        final artifacts = await exportService.buildImages(
          request: state.request,
          pages: state.pages,
        );
        if (artifacts.length > 1) {
          final zip = exportService.buildImagesZip(
            year: state.request.year,
            images: artifacts,
          );
          await _shareArtifacts([zip], title: 'Calendar Images ZIP');
        } else {
          await _shareArtifacts(artifacts, title: 'Calendar Images');
        }
        if (!mounted) {
          return;
        }
        if (artifacts.length > 1) {
          _showSnack(
            'Generated ${artifacts.length} images and shared ZIP bundle.',
          );
        } else {
          _showSnack('Generated 1 image file.');
        }
      },
    );
  }

  Future<void> _printPdf() async {
    await _runGenerationAction(
      actionLabel: 'Preparing print',
      onRun: (state) async {
        await getIt<CalendarExportService>().print(
          request: state.request,
          pages: state.pages,
        );
      },
    );
  }

  Future<void> _runGenerationAction({
    required String actionLabel,
    required Future<void> Function(CalendarGenerationLoaded state) onRun,
  }) async {
    final state = context.read<CalendarGenerationBloc>().state;
    if (state is! CalendarGenerationLoaded) {
      _showSnack('Calendar preview is still loading.');
      return;
    }

    setState(() {
      _isProcessingAction = true;
      _processingLabel = actionLabel;
    });

    try {
      await onRun(state);
    } catch (error) {
      if (mounted) {
        _showSnack('Failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
          _processingLabel = null;
        });
      }
    }
  }

  Future<void> _shareArtifacts(
    List<GenerationArtifact> artifacts, {
    required String title,
  }) async {
    final files = artifacts
        .map(
          (artifact) => XFile.fromData(
            artifact.bytes,
            mimeType: artifact.mimeType,
            name: artifact.fileName,
          ),
        )
        .toList(growable: false);

    await share(
      title: title,
      subject: artifacts.length == 1
          ? artifacts.first.fileName
          : 'Myanmar calendar exports',
      files: files,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({
    required this.label,
    required this.colors,
    required this.selectedValue,
    required this.onColorSelected,
  });

  final String label;
  final List<Color> colors;
  final int selectedValue;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors
              .map((color) {
                final selected = color.toARGB32() == selectedValue;
                final borderColor = selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent;

                return InkWell(
                  onTap: () => onColorSelected(color),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

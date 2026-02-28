import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_core/shared_core.dart';

import '../../di/calendar_generation_injection.dart';
import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_generation_template.dart';
import '../../domain/entities/calendar_image_quality.dart';
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
  final TextEditingController _templateNameController = TextEditingController();
  final FocusNode _imageUrlFocusNode = FocusNode();

  int _previewPage = 0;
  bool _isProcessingAction = false;
  String? _processingLabel;
  int? _imageOverrideMonth;
  String? _selectedTemplateId;

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
    _templateNameController.dispose();
    _imageUrlFocusNode.dispose();
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

              return _buildLoadedBody(state as CalendarGenerationLoaded);
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

  Widget _buildLoadedBody(CalendarGenerationLoaded state) {
    final request = state.request;
    final pages = state.pages;

    return Column(
      children: [
        _buildSettingsLauncherRow(),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  request.mode == CalendarGenerationMode.month
                      ? 'Month Preview'
                      : 'Year Preview (${pages.length} pages)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('Lang: ${request.language.name.capitalize}'),
            ],
          ),
        ),
        Expanded(
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Page ${_previewPage + 1} / ${pages.length}'),
          ),
      ],
    );
  }

  Widget _buildSettingsLauncherRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SettingsGroupButton(
              icon: Icons.tune,
              label: 'General',
              onTap: _openGeneralSettingsSheet,
            ),
            _SettingsGroupButton(
              icon: Icons.aspect_ratio,
              label: 'Layout',
              onTap: _openLayoutSettingsSheet,
            ),
            _SettingsGroupButton(
              icon: Icons.visibility_outlined,
              label: 'Visibility',
              onTap: _openVisibilitySettingsSheet,
            ),
            _SettingsGroupButton(
              icon: Icons.palette_outlined,
              label: 'Theme',
              onTap: _openThemeSettingsSheet,
            ),
            _SettingsGroupButton(
              icon: Icons.image_outlined,
              label: 'Background',
              onTap: _openBackgroundSettingsSheet,
            ),
            _SettingsGroupButton(
              icon: Icons.bookmarks_outlined,
              label: 'Templates',
              onTap: _openTemplateSettingsSheet,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGeneralSettingsSheet() async {
    await _showSettingsSheet(
      title: 'General Settings',
      contentBuilder: (context, state) {
        final request = state.request;
        final now = DateTime.now();
        final years = List<int>.generate(12, (index) => now.year - 5 + index);

        return Column(
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
              selected: <CalendarGenerationMode>{request.mode},
              onSelectionChanged: (selection) {
                context.read<CalendarGenerationBloc>().add(
                  ChangeGenerationMode(selection.first),
                );
              },
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
        );
      },
    );
  }

  Future<void> _openLayoutSettingsSheet() async {
    await _showSettingsSheet(
      title: 'Layout Settings',
      contentBuilder: (context, state) {
        final request = state.request;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),
            DropdownButtonFormField<CalendarImageQuality>(
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
            const SizedBox(height: 12),
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
              selected: <CalendarPageOrientation>{request.pageOrientation},
              onSelectionChanged: (selection) {
                context.read<CalendarGenerationBloc>().add(
                  ChangePageOrientation(selection.first),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openVisibilitySettingsSheet() async {
    await _showSettingsSheet(
      title: 'Visibility Settings',
      contentBuilder: (context, state) {
        final request = state.request;
        return Column(
          children: [
            SwitchListTile.adaptive(
              title: const Text('Show Holidays'),
              value: request.showHolidays,
              onChanged: (value) {
                context.read<CalendarGenerationBloc>().add(
                  ToggleGenerationHolidays(value),
                );
              },
            ),
            SwitchListTile.adaptive(
              title: const Text('Show Astrology'),
              value: request.showAstrology,
              onChanged: (value) {
                context.read<CalendarGenerationBloc>().add(
                  ToggleGenerationAstrology(value),
                );
              },
            ),
            SwitchListTile.adaptive(
              title: const Text('Show Western Dates'),
              value: request.showWesternDates,
              onChanged: (value) {
                context.read<CalendarGenerationBloc>().add(
                  ToggleGenerationWesternDates(value),
                );
              },
            ),
            SwitchListTile.adaptive(
              title: const Text('Show Myanmar Dates'),
              value: request.showMyanmarDates,
              onChanged: (value) {
                context.read<CalendarGenerationBloc>().add(
                  ToggleGenerationMyanmarDates(value),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openThemeSettingsSheet() async {
    await _showSettingsSheet(
      title: 'Theme Settings',
      contentBuilder: (context, state) {
        final request = state.request;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ColorSelector(
              label: 'Background',
              colors: _presetColors,
              selectedValue: request.theme.backgroundColorValue,
              onColorSelected: (color) {
                context.read<CalendarGenerationBloc>().add(
                  ChangeBackgroundColor(color.toARGB32()),
                );
              },
            ),
            const SizedBox(height: 12),
            _ColorSelector(
              label: 'Foreground',
              colors: _presetColors,
              selectedValue: request.theme.foregroundColorValue,
              onColorSelected: (color) {
                context.read<CalendarGenerationBloc>().add(
                  ChangeForegroundColor(color.toARGB32()),
                );
              },
            ),
            const SizedBox(height: 12),
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
          ],
        );
      },
    );
  }

  Future<void> _openBackgroundSettingsSheet() async {
    final bloc = context.read<CalendarGenerationBloc>();
    var selectedMonth = _imageOverrideMonth;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (providedContext) {
              final bottomInset = MediaQuery.viewInsetsOf(
                providedContext,
              ).bottom;
              return FractionallySizedBox(
                heightFactor: 0.92,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 12),
                  child: StatefulBuilder(
                    builder: (context, setModalState) {
                      return BlocBuilder<
                        CalendarGenerationBloc,
                        CalendarGenerationState
                      >(
                        builder: (context, state) {
                          if (state is! CalendarGenerationLoaded) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final selectedImage = _selectedBackgroundImageFor(
                            state.request,
                            monthOverride: selectedMonth,
                          );
                          final inputValue = _isDataImageUri(selectedImage)
                              ? ''
                              : selectedImage;
                          if (!_imageUrlFocusNode.hasFocus &&
                              _imageUrlController.text != inputValue) {
                            _imageUrlController.text = inputValue;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SettingsSheetHeader(
                                title: 'Background Settings',
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<int?>(
                                        initialValue: selectedMonth,
                                        decoration: const InputDecoration(
                                          labelText: 'Image Scope',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: <DropdownMenuItem<int?>>[
                                          const DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text('Default (All months)'),
                                          ),
                                          ...List<
                                            DropdownMenuItem<int?>
                                          >.generate(
                                            12,
                                            (index) => DropdownMenuItem<int?>(
                                              value: index + 1,
                                              child: Text('Month ${index + 1}'),
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setModalState(() {
                                            selectedMonth = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _imageUrlController,
                                        focusNode: _imageUrlFocusNode,
                                        decoration: InputDecoration(
                                          labelText: selectedMonth == null
                                              ? 'Background Image URL (optional)'
                                              : 'Month ${selectedMonth!} Image URL (optional)',
                                          border: const OutlineInputBorder(),
                                        ),
                                        onSubmitted: (value) {
                                          _applyBackgroundImageUrl(
                                            value.trim(),
                                            monthOverride: selectedMonth,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          FilledButton.icon(
                                            onPressed: () =>
                                                _pickBackgroundImage(
                                                  monthOverride: selectedMonth,
                                                ),
                                            icon: const Icon(
                                              Icons.photo_library_outlined,
                                            ),
                                            label: const Text('Pick Image'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _applyBackgroundImageUrl(
                                                  '',
                                                  monthOverride: selectedMonth,
                                                ),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            label: const Text('Clear'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _applyBackgroundImageUrl(
                                                  _imageUrlController.text
                                                      .trim(),
                                                  monthOverride: selectedMonth,
                                                ),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Apply URL'),
                                          ),
                                        ],
                                      ),
                                      if (_isDataImageUri(selectedImage))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            'Using picked image from device for this scope.',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _imageOverrideMonth = selectedMonth;
    });
  }

  Future<void> _openTemplateSettingsSheet() async {
    await _showSettingsSheet(
      title: 'Template Settings',
      contentBuilder: (context, state) {
        final templates = state.templates;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _templateNameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _saveTemplateWithProtection(templates),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _saveTemplateWithProtection(templates),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save Current As Template'),
            ),
            const SizedBox(height: 12),
            Text(
              'Saved Templates',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (templates.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No saved templates yet.'),
              )
            else
              Column(
                children: templates
                    .map((template) {
                      final isSelected = _selectedTemplateId == template.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          selected: isSelected,
                          title: Text(template.name),
                          subtitle: Text(
                            'Language: ${template.language.name.capitalize}',
                          ),
                          onTap: () {
                            setState(() {
                              _selectedTemplateId = template.id;
                            });
                            context.read<CalendarGenerationBloc>().add(
                              ApplyGenerationTemplate(template.id),
                            );
                            _showSnack('Template applied: ${template.name}');
                          },
                          trailing: PopupMenuButton<_TemplateAction>(
                            onSelected: (action) {
                              switch (action) {
                                case _TemplateAction.rename:
                                  _renameTemplate(template, templates);
                                case _TemplateAction.delete:
                                  _deleteTemplate(template);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem<_TemplateAction>(
                                value: _TemplateAction.rename,
                                child: Text('Rename'),
                              ),
                              PopupMenuItem<_TemplateAction>(
                                value: _TemplateAction.delete,
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showSettingsSheet({
    required String title,
    required Widget Function(
      BuildContext context,
      CalendarGenerationLoaded state,
    )
    contentBuilder,
  }) async {
    final bloc = context.read<CalendarGenerationBloc>();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (providedContext) {
              final bottomInset = MediaQuery.viewInsetsOf(
                providedContext,
              ).bottom;
              return FractionallySizedBox(
                heightFactor: 0.92,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 12),
                  child:
                      BlocBuilder<
                        CalendarGenerationBloc,
                        CalendarGenerationState
                      >(
                        builder: (context, state) {
                          if (state is! CalendarGenerationLoaded) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SettingsSheetHeader(title: title),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: contentBuilder(context, state),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                ),
              );
            },
          ),
        );
      },
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

  void _applyBackgroundImageUrl(String url, {int? monthOverride}) {
    final bloc = context.read<CalendarGenerationBloc>();
    final normalizedUrl = url.trim();
    if (monthOverride == null) {
      bloc.add(ChangeBackgroundImageUrl(normalizedUrl));
    } else {
      bloc.add(
        ChangeMonthBackgroundImageUrl(month: monthOverride, url: normalizedUrl),
      );
    }
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickBackgroundImage({int? monthOverride}) async {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (!mounted || selected == null || selected.files.isEmpty) {
      return;
    }

    final file = selected.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showSnack('Unable to read selected image.');
      return;
    }

    final mimeType = _mimeTypeFromExtension(file.extension);
    final dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';
    _applyBackgroundImageUrl(dataUri, monthOverride: monthOverride);
    _showSnack('Selected image applied.');
  }

  Future<void> _saveTemplateWithProtection(
    List<CalendarGenerationTemplate> templates,
  ) async {
    final name = _templateNameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Template name is required.');
      return;
    }

    final existing = _findTemplateByName(templates, name);
    if (existing != null) {
      final shouldOverwrite = await _confirmTemplateOverwrite(name);
      if (!mounted || !shouldOverwrite) {
        return;
      }
    }

    context.read<CalendarGenerationBloc>().add(SaveGenerationTemplate(name));
    setState(() {
      _selectedTemplateId = existing?.id ?? _selectedTemplateId;
    });
    _templateNameController.clear();
    _showSnack(
      existing == null
          ? 'Template saved.'
          : 'Template overwritten successfully.',
    );
  }

  Future<void> _renameTemplate(
    CalendarGenerationTemplate template,
    List<CalendarGenerationTemplate> templates,
  ) async {
    final controller = TextEditingController(text: template.name);
    final nextName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Template'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Template Name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || nextName == null || nextName.isEmpty) {
      return;
    }

    final duplicate = _findTemplateByName(
      templates,
      nextName,
      excludingTemplateId: template.id,
    );
    if (duplicate != null) {
      _showSnack('Template name already exists. Use a different name.');
      return;
    }

    context.read<CalendarGenerationBloc>().add(
      RenameGenerationTemplate(templateId: template.id, name: nextName),
    );
    _showSnack('Template renamed.');
  }

  Future<void> _deleteTemplate(CalendarGenerationTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Template'),
          content: Text('Delete "${template.name}" template?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }

    context.read<CalendarGenerationBloc>().add(
      DeleteGenerationTemplate(template.id),
    );
    if (_selectedTemplateId == template.id) {
      setState(() {
        _selectedTemplateId = null;
      });
    }
    _showSnack('Template deleted.');
  }

  Future<bool> _confirmTemplateOverwrite(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Template Exists'),
          content: Text(
            'A template named "$name" already exists. Do you want to replace it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  CalendarGenerationTemplate? _findTemplateByName(
    List<CalendarGenerationTemplate> templates,
    String name, {
    String? excludingTemplateId,
  }) {
    final normalized = name.trim().toLowerCase();
    for (final template in templates) {
      if (excludingTemplateId != null && template.id == excludingTemplateId) {
        continue;
      }
      if (template.name.trim().toLowerCase() == normalized) {
        return template;
      }
    }
    return null;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _selectedBackgroundImageFor(
    CalendarGenerationRequest request, {
    int? monthOverride,
  }) {
    if (monthOverride == null) {
      return request.theme.backgroundImageUrl ?? '';
    }
    return request.theme.backgroundImageUrlsByMonth[monthOverride] ?? '';
  }

  String _mimeTypeFromExtension(String? extension) {
    final ext = extension?.toLowerCase().trim();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'bmp' => 'image/bmp',
      'heic' => 'image/heic',
      _ => 'image/png',
    };
  }

  bool _isDataImageUri(String value) {
    return value.startsWith('data:image/') && value.contains(';base64,');
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

class _SettingsGroupButton extends StatelessWidget {
  const _SettingsGroupButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _SettingsSheetHeader extends StatelessWidget {
  const _SettingsSheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ],
    );
  }
}

enum _TemplateAction { rename, delete }

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:overlay_editor/overlay_editor.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_core/shared_core.dart';

import '../../di/calendar_generation_injection.dart';
import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_generation_template.dart';
import '../../domain/entities/calendar_overlay_element.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/generation_artifact.dart';
import '../../domain/usecases/build_calendar_previews.dart';
import '../../rendering/export/calendar_export_layout.dart';
import '../../rendering/export/calendar_export_service.dart';
import '../bloc/calendar_generation_bloc.dart';
import '../bloc/calendar_generation_event.dart';
import '../bloc/calendar_generation_state.dart';
import '../widgets/calendar_generation_layout_panels.dart';
import '../widgets/calendar_generation_preview_page.dart';
import '../widgets/calendar_generation_settings_content.dart';
import '../widgets/calendar_generation_template_grid.dart';
import '../widgets/calendar_generation_ui_sections.dart';

OverlayEditorItem _toOverlayEditorItem(CalendarOverlayElement element) {
  return OverlayEditorItem(
    id: element.id,
    type: switch (element.type) {
      CalendarOverlayElementType.text => OverlayEditorItemType.text,
      CalendarOverlayElementType.emoji => OverlayEditorItemType.emoji,
      CalendarOverlayElementType.sticker => OverlayEditorItemType.sticker,
      CalendarOverlayElementType.image => OverlayEditorItemType.image,
    },
    x: element.x,
    y: element.y,
    scale: element.scale,
    rotation: element.rotation,
    locked: element.locked,
    opacity: element.opacity,
    text: element.text,
    stickerKey: element.stickerKey,
    imageSource: element.imageSource,
    colorValue: element.colorValue,
    baseSize: element.baseSize,
  );
}

CalendarOverlayElement _toCalendarOverlayElement(OverlayEditorItem item) {
  return CalendarOverlayElement(
    id: item.id,
    type: switch (item.type) {
      OverlayEditorItemType.text => CalendarOverlayElementType.text,
      OverlayEditorItemType.emoji => CalendarOverlayElementType.emoji,
      OverlayEditorItemType.sticker => CalendarOverlayElementType.sticker,
      OverlayEditorItemType.image => CalendarOverlayElementType.image,
    },
    x: item.x,
    y: item.y,
    scale: item.scale,
    rotation: item.rotation,
    locked: item.locked,
    opacity: item.opacity,
    text: item.text,
    stickerKey: item.stickerKey,
    imageSource: item.imageSource,
    colorValue: item.colorValue,
    baseSize: item.baseSize,
  );
}

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
  final PageController _previewPageController = PageController();

  int _previewPage = 0;
  bool _isProcessingAction = false;
  String? _processingLabel;
  int? _imageOverrideMonth;
  String? _selectedTemplateId;
  int? _templatePreviewCacheKey;
  CalendarPageOrientation? _previewOrientationOverride;
  bool _syncPreviewOrientationToExport = false;
  final Map<String, CalendarTemplatePreviewData> _templatePreviewCache =
      <String, CalendarTemplatePreviewData>{};

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
    _previewPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Generation'),
        actions: [
          IconButton(
            onPressed: _isProcessingAction ? null : _openOverlayEditor,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Overlays',
          ),
          PopupMenuButton<_QuickExportAction>(
            enabled: !_isProcessingAction,
            tooltip: 'Export actions',
            icon: const Icon(Icons.ios_share_outlined),
            onSelected: (action) {
              switch (action) {
                case _QuickExportAction.sharePdf:
                  _exportPdf();
                  break;
                case _QuickExportAction.savePdf:
                  _savePdfToDevice();
                  break;
                case _QuickExportAction.shareImages:
                  _exportImages();
                  break;
                case _QuickExportAction.saveImages:
                  _saveImagesToDevice();
                  break;
                case _QuickExportAction.printPdf:
                  _printPdf();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<_QuickExportAction>(
                value: _QuickExportAction.sharePdf,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Share PDF'),
                ),
              ),
              PopupMenuItem<_QuickExportAction>(
                value: _QuickExportAction.savePdf,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.save_alt_outlined),
                  title: Text('Save PDF to folder'),
                ),
              ),
              PopupMenuItem<_QuickExportAction>(
                value: _QuickExportAction.shareImages,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.image_outlined),
                  title: Text('Share images'),
                ),
              ),
              PopupMenuItem<_QuickExportAction>(
                value: _QuickExportAction.saveImages,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.folder_copy_outlined),
                  title: Text('Save images to folder'),
                ),
              ),
              PopupMenuItem<_QuickExportAction>(
                value: _QuickExportAction.printPdf,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.print_outlined),
                  title: Text('Print PDF'),
                ),
              ),
            ],
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
    final previewOrientation = _syncPreviewOrientationToExport
        ? request.pageOrientation
        : (_previewOrientationOverride ?? request.pageOrientation);
    final previewRequest = request.copyWith(
      pageOrientation: previewOrientation,
    );
    final previewCanvasSize = _resolvePreviewCanvasSize(previewRequest);
    final pages = state.pages;
    if (pages.isEmpty) {
      return const Center(child: Text('No preview pages available.'));
    }
    final safePreviewPage = _previewPage.clamp(
      0,
      (pages.length - 1).clamp(0, 9999),
    );
    final activePage = pages.isEmpty ? null : pages[safePreviewPage];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideLayout = constraints.maxWidth >= 1080;
        if (!isWideLayout) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                CalendarGenerationSettingsLauncherCard(
                  onGeneralTap: _openGeneralSettingsSheet,
                  onLayoutTap: _openLayoutSettingsSheet,
                  onVisibilityTap: _openVisibilitySettingsSheet,
                  onThemeTap: _openThemeSettingsSheet,
                  onBackgroundTap: _openBackgroundSettingsSheet,
                  onTemplateTap: _openTemplateSettingsSheet,
                ),
                const SizedBox(height: 10),
                CalendarGenerationPreviewSummaryCard(
                  request: request,
                  pages: pages,
                  previewOrientation: previewOrientation,
                  activePage: activePage,
                  syncPreviewOrientationToExport:
                      _syncPreviewOrientationToExport,
                  onPreviewOrientationChanged: (selected) {
                    if (_syncPreviewOrientationToExport) {
                      context.read<CalendarGenerationBloc>().add(
                        ChangePageOrientation(selected),
                      );
                      return;
                    }
                    setState(() => _previewOrientationOverride = selected);
                  },
                  onSyncPreviewOrientationChanged: (value) {
                    setState(() => _syncPreviewOrientationToExport = value);
                    if (!value) {
                      return;
                    }
                    final orientation =
                        _previewOrientationOverride ?? request.pageOrientation;
                    _previewOrientationOverride = null;
                    context.read<CalendarGenerationBloc>().add(
                      ChangePageOrientation(orientation),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: CalendarGenerationPreviewWorkspace(
                    pages: pages,
                    previewPage: _previewPage,
                    previewPageController: _previewPageController,
                    previewRequest: previewRequest,
                    previewCanvasSize: previewCanvasSize,
                    onPageChanged: (index) {
                      setState(() {
                        _previewPage = index;
                      });
                    },
                    onGoToPage: _goToPreviewPage,
                  ),
                ),
              ],
            ),
          );
        }

        final controlsWidth = (constraints.maxWidth * 0.34).clamp(340.0, 440.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: controlsWidth.toDouble(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      CalendarGenerationSettingsLauncherCard(
                        onGeneralTap: _openGeneralSettingsSheet,
                        onLayoutTap: _openLayoutSettingsSheet,
                        onVisibilityTap: _openVisibilitySettingsSheet,
                        onThemeTap: _openThemeSettingsSheet,
                        onBackgroundTap: _openBackgroundSettingsSheet,
                        onTemplateTap: _openTemplateSettingsSheet,
                      ),
                      const SizedBox(height: 10),
                      CalendarGenerationPreviewSummaryCard(
                        request: request,
                        pages: pages,
                        previewOrientation: previewOrientation,
                        activePage: activePage,
                        syncPreviewOrientationToExport:
                            _syncPreviewOrientationToExport,
                        onPreviewOrientationChanged: (selected) {
                          if (_syncPreviewOrientationToExport) {
                            context.read<CalendarGenerationBloc>().add(
                              ChangePageOrientation(selected),
                            );
                            return;
                          }
                          setState(
                            () => _previewOrientationOverride = selected,
                          );
                        },
                        onSyncPreviewOrientationChanged: (value) {
                          setState(
                            () => _syncPreviewOrientationToExport = value,
                          );
                          if (!value) {
                            return;
                          }
                          final orientation =
                              _previewOrientationOverride ??
                              request.pageOrientation;
                          _previewOrientationOverride = null;
                          context.read<CalendarGenerationBloc>().add(
                            ChangePageOrientation(orientation),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CalendarGenerationPreviewWorkspace(
                  pages: pages,
                  previewPage: _previewPage,
                  previewPageController: _previewPageController,
                  previewRequest: previewRequest,
                  previewCanvasSize: previewCanvasSize,
                  onPageChanged: (index) {
                    setState(() {
                      _previewPage = index;
                    });
                  },
                  onGoToPage: _goToPreviewPage,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToPreviewPage(int page) {
    if (!_previewPageController.hasClients) {
      setState(() {
        _previewPage = page;
      });
      return;
    }
    _previewPageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Size _resolvePreviewCanvasSize(CalendarGenerationRequest request) {
    final previewSize = CalendarExportLayout.resolvePreviewCanvasSize(request);
    return Size(previewSize.width, previewSize.height);
  }

  Future<void> _openGeneralSettingsSheet() async {
    await _showSettingsSheet(
      title: 'General Settings',
      contentBuilder: (context, state) =>
          CalendarGeneralSettingsContent(request: state.request),
    );
  }

  Future<void> _openLayoutSettingsSheet() async {
    await _showSettingsSheet(
      title: 'Layout Settings',
      contentBuilder: (context, state) =>
          CalendarLayoutSettingsContent(request: state.request),
    );
  }

  Future<void> _openVisibilitySettingsSheet() async {
    await _showSettingsSheet(
      title: 'Visibility Settings',
      contentBuilder: (context, state) =>
          CalendarVisibilitySettingsContent(request: state.request),
    );
  }

  Future<void> _openThemeSettingsSheet() async {
    await _showSettingsSheet(
      title: 'Theme Settings',
      contentBuilder: (context, state) => CalendarThemeSettingsContent(
        request: state.request,
        presetColors: _presetColors,
      ),
    );
  }

  Future<void> _openBackgroundSettingsSheet() async {
    final bloc = context.read<CalendarGenerationBloc>();
    var selectedMonth = _imageOverrideMonth;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
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
                        bloc: bloc,
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
                              const SettingsSheetHeader(
                                title: 'Background Settings',
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: CalendarBackgroundSettingsContent(
                                    request: state.request,
                                    selectedMonth: selectedMonth,
                                    selectedImage: selectedImage,
                                    imageUrlController: _imageUrlController,
                                    imageUrlFocusNode: _imageUrlFocusNode,
                                    onMonthChanged: (value) {
                                      setModalState(() {
                                        selectedMonth = value;
                                      });
                                    },
                                    onSubmittedUrl: (value) {
                                      _applyBackgroundImageUrl(
                                        value.trim(),
                                        monthOverride: selectedMonth,
                                      );
                                    },
                                    onPickImage: () => _pickBackgroundImage(
                                      monthOverride: selectedMonth,
                                    ),
                                    onClear: () => _applyBackgroundImageUrl(
                                      '',
                                      monthOverride: selectedMonth,
                                    ),
                                    onApplyUrl: () => _applyBackgroundImageUrl(
                                      _imageUrlController.text.trim(),
                                      monthOverride: selectedMonth,
                                    ),
                                    showPickedImageHint: _isDataImageUri(
                                      selectedImage,
                                    ),
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
        final templatePreviewById = _templatePreviewsFor(state);

        return CalendarTemplateSettingsContent(
          templates: templates,
          templatePreviewById: templatePreviewById,
          selectedTemplateId: _selectedTemplateId,
          templateNameController: _templateNameController,
          onSaveTemplate: () => _saveTemplateWithProtection(templates),
          onApplyTemplate: _applyTemplate,
          onRenameTemplate: (template) => _renameTemplate(template, templates),
          onDeleteTemplate: _deleteTemplate,
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
      showDragHandle: true,
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
                        bloc: bloc,
                        builder: (context, state) {
                          if (state is! CalendarGenerationLoaded) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SettingsSheetHeader(title: title),
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

  Future<void> _openOverlayEditor() async {
    final state = context.read<CalendarGenerationBloc>().state;
    if (state is! CalendarGenerationLoaded) {
      _showSnack('Calendar preview is still loading.');
      return;
    }
    if (state.pages.isEmpty) {
      _showSnack('No pages available for editing.');
      return;
    }

    final previewOrientation = _syncPreviewOrientationToExport
        ? state.request.pageOrientation
        : (_previewOrientationOverride ?? state.request.pageOrientation);
    final editorRequest = state.request.copyWith(
      pageOrientation: previewOrientation,
    );
    final editorPages = getIt<BuildCalendarPreviews>()(editorRequest);
    if (editorPages.isEmpty) {
      _showSnack('No pages available for editing.');
      return;
    }

    if (previewOrientation != state.request.pageOrientation) {
      context.read<CalendarGenerationBloc>().add(
        ChangePageOrientation(previewOrientation),
      );
    }

    final previewCanvasSize = _resolvePreviewCanvasSize(editorRequest);
    final editorPageData = editorPages
        .map(
          (page) => OverlayEditorPageData(
            pageKey: page.month,
            title: page.westernTitle,
            subtitle: page.myanmarTitle,
            canvasSize: previewCanvasSize,
            overlayPadding: const EdgeInsets.all(12),
            items:
                (state.request.overlayElementsByMonth[page.month] ??
                        const <CalendarOverlayElement>[])
                    .map(_toOverlayEditorItem)
                    .toList(growable: false),
            preview: CalendarGenerationPreviewPage(
              model: page,
              request: editorRequest,
              margin: EdgeInsets.zero,
              elevation: 0,
              contentPadding: const EdgeInsets.all(12),
              useCardChrome: false,
              showOverlayElements: false,
            ),
          ),
        )
        .toList(growable: false);

    final result = await Navigator.of(context).push<OverlayEditorResult>(
      MaterialPageRoute<OverlayEditorResult>(
        fullscreenDialog: true,
        builder: (context) => OverlayEditorPage(
          pages: editorPageData,
          initialPageIndex: _previewPage,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    final mapped = <int, List<CalendarOverlayElement>>{};
    for (final entry in result.itemsByPageKey.entries) {
      mapped[entry.key] = entry.value
          .map(_toCalendarOverlayElement)
          .toList(growable: false);
    }

    context.read<CalendarGenerationBloc>().add(
      ReplaceOverlayElementsByMonth(mapped),
    );

    final targetPage = result.pageIndex.clamp(0, editorPages.length - 1);
    if (targetPage != _previewPage) {
      _goToPreviewPage(targetPage);
    }
  }

  Future<void> _exportPdf() async {
    await _runGenerationAction(
      actionLabel: 'Generating PDF',
      onRun: (state) async {
        final request = _resolvedRequestForGeneration(state.request);
        final artifact = await getIt<CalendarExportService>().buildPdf(
          request: request,
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
        final request = _resolvedRequestForGeneration(state.request);
        final exportService = getIt<CalendarExportService>();
        final artifacts = await exportService.buildImages(
          request: request,
          pages: state.pages,
        );
        if (artifacts.length > 1) {
          final zip = await exportService.buildImagesZip(
            year: request.year,
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

  Future<void> _savePdfToDevice() async {
    await _runGenerationAction(
      actionLabel: 'Saving PDF',
      onRun: (state) async {
        final request = _resolvedRequestForGeneration(state.request);
        final artifact = await getIt<CalendarExportService>().buildPdf(
          request: request,
          pages: state.pages,
        );
        final directory = await _pickTargetDirectory();
        if (!mounted || directory == null) {
          return;
        }
        await _writeArtifactsToDirectory(
          artifacts: [artifact],
          directoryPath: directory,
        );
        if (!mounted) {
          return;
        }
        _showSnack('Saved PDF to $directory');
      },
    );
  }

  Future<void> _saveImagesToDevice() async {
    await _runGenerationAction(
      actionLabel: 'Saving images',
      onRun: (state) async {
        final request = _resolvedRequestForGeneration(state.request);
        final artifacts = await getIt<CalendarExportService>().buildImages(
          request: request,
          pages: state.pages,
        );
        final directory = await _pickTargetDirectory();
        if (!mounted || directory == null) {
          return;
        }
        await _writeArtifactsToDirectory(
          artifacts: artifacts,
          directoryPath: directory,
        );
        if (!mounted) {
          return;
        }
        _showSnack('Saved ${artifacts.length} image file(s) to $directory');
      },
    );
  }

  Future<void> _printPdf() async {
    await _runGenerationAction(
      actionLabel: 'Preparing print',
      onRun: (state) async {
        final request = _resolvedRequestForGeneration(state.request);
        await getIt<CalendarExportService>().print(
          request: request,
          pages: state.pages,
        );
      },
    );
  }

  CalendarGenerationRequest _resolvedRequestForGeneration(
    CalendarGenerationRequest request,
  ) {
    return request;
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

  Future<String?> _pickTargetDirectory() {
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder to save exported files',
      lockParentWindow: true,
    );
  }

  Future<void> _writeArtifactsToDirectory({
    required List<GenerationArtifact> artifacts,
    required String directoryPath,
  }) async {
    for (final artifact in artifacts) {
      final file = File(
        '$directoryPath${Platform.pathSeparator}${artifact.fileName}',
      );
      await file.create(recursive: true);
      await file.writeAsBytes(artifact.bytes, flush: true);
    }
  }

  void _applyBackgroundImageUrl(String url, {int? monthOverride}) {
    final bloc = context.read<CalendarGenerationBloc>();
    final normalizedUrl = _normalizeBackgroundImageUrl(url);
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
      withData: false,
    );
    if (!mounted || selected == null || selected.files.isEmpty) {
      return;
    }

    final file = selected.files.first;
    final path = file.path?.trim();
    if (path == null || path.isEmpty) {
      _showSnack('Unable to access selected image path.');
      return;
    }

    _applyBackgroundImageUrl(
      Uri.file(path).toString(),
      monthOverride: monthOverride,
    );
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

  void _applyTemplate(CalendarGenerationTemplate template) {
    setState(() {
      _selectedTemplateId = template.id;
    });
    context.read<CalendarGenerationBloc>().add(
      ApplyGenerationTemplate(template.id),
    );
    _showSnack('Template applied: ${template.name}');
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

  Map<String, CalendarTemplatePreviewData> _templatePreviewsFor(
    CalendarGenerationLoaded state,
  ) {
    final nextCacheKey = Object.hash(
      state.request.year,
      state.request.month,
      state.request.calendarConfig,
      state.request.useDeviceTimezone,
      Object.hashAll(state.templates),
    );
    if (_templatePreviewCacheKey == nextCacheKey) {
      return _templatePreviewCache;
    }

    final builder = getIt<BuildCalendarPreviews>();
    final preferredMonth = state.request.month ?? DateTime.now().month;
    final nextPreviews = <String, CalendarTemplatePreviewData>{};

    for (final template in state.templates) {
      final request = _requestForTemplate(state.request, template);
      final pages = builder(request);
      if (pages.isEmpty) {
        continue;
      }

      nextPreviews[template.id] = CalendarTemplatePreviewData(
        request: request,
        model: _pickTemplatePreviewPage(
          pages,
          mode: template.mode,
          preferredMonth: preferredMonth,
        ),
      );
    }

    _templatePreviewCache
      ..clear()
      ..addAll(nextPreviews);
    _templatePreviewCacheKey = nextCacheKey;
    return _templatePreviewCache;
  }

  CalendarGenerationRequest _requestForTemplate(
    CalendarGenerationRequest baseRequest,
    CalendarGenerationTemplate template,
  ) {
    return baseRequest.copyWith(
      mode: template.mode,
      language: template.language,
      showHolidays: template.showHolidays,
      showAstrology: template.showAstrology,
      showWesternDates: template.showWesternDates,
      showMyanmarDates: template.showMyanmarDates,
      firstDayOfWeek: template.firstDayOfWeek,
      paperSize: template.paperSize,
      pageOrientation: template.pageOrientation,
      landscapeDecorationAreaSide: template.landscapeDecorationAreaSide,
      imageQuality: template.imageQuality,
      theme: template.theme,
    );
  }

  CalendarPageModel _pickTemplatePreviewPage(
    List<CalendarPageModel> pages, {
    required CalendarGenerationMode mode,
    required int preferredMonth,
  }) {
    if (mode == CalendarGenerationMode.month) {
      return pages.first;
    }
    for (final page in pages) {
      if (page.month == preferredMonth) {
        return page;
      }
    }
    return pages.first;
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

  String _normalizeBackgroundImageUrl(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.hasScheme) {
      return normalized;
    }

    if (_looksLikeAbsoluteLocalPath(normalized)) {
      return Uri.file(normalized).toString();
    }

    return normalized;
  }

  bool _isDataImageUri(String value) {
    return value.startsWith('data:image/') && value.contains(';base64,');
  }

  bool _looksLikeAbsoluteLocalPath(String value) {
    if (value.startsWith('/')) {
      return true;
    }
    return RegExp(r'^[a-zA-Z]:[\\\/]').hasMatch(value);
  }
}

enum _QuickExportAction { sharePdf, savePdf, shareImages, saveImages, printPdf }

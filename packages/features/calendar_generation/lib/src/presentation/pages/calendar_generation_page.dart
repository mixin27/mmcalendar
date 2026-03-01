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
import '../widgets/calendar_generation_app_bar_actions.dart';
import '../widgets/calendar_generation_layout_panels.dart';
import '../widgets/calendar_generation_preview_page.dart';
import '../widgets/calendar_generation_settings_content.dart';
import '../widgets/calendar_generation_template_grid.dart';
import '../widgets/calendar_generation_ui_sections.dart';

part 'calendar_generation_page_actions.part.dart';
part 'calendar_generation_page_background.part.dart';
part 'calendar_generation_page_settings.part.dart';
part 'calendar_generation_page_template.part.dart';

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
          CalendarGenerationAppBarActions(
            isProcessing: _isProcessingAction,
            onOpenOverlayEditor: _openOverlayEditor,
            onQuickActionSelected: _onQuickActionSelected,
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
                _buildMobileControlsBar(
                  request: request,
                  pages: pages,
                  previewOrientation: previewOrientation,
                  activePage: activePage,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CalendarGenerationPreviewWorkspace(
                    pages: pages,
                    previewPage: _previewPage,
                    previewPageController: _previewPageController,
                    previewRequest: previewRequest,
                    previewCanvasSize: previewCanvasSize,
                    onPageChanged: _onPreviewPageChanged,
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
                  child: _buildSettingsAndSummaryPanel(
                    request: request,
                    pages: pages,
                    previewOrientation: previewOrientation,
                    activePage: activePage,
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
                  onPageChanged: _onPreviewPageChanged,
                  onGoToPage: _goToPreviewPage,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsAndSummaryPanel({
    required CalendarGenerationRequest request,
    required List<CalendarPageModel> pages,
    required CalendarPageOrientation previewOrientation,
    required CalendarPageModel? activePage,
  }) {
    return Column(
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
          syncPreviewOrientationToExport: _syncPreviewOrientationToExport,
          onPreviewOrientationChanged: _onPreviewOrientationChanged,
          onSyncPreviewOrientationChanged: (value) =>
              _onSyncPreviewOrientationChanged(value, request),
        ),
      ],
    );
  }

  Widget _buildMobileControlsBar({
    required CalendarGenerationRequest request,
    required List<CalendarPageModel> pages,
    required CalendarPageOrientation previewOrientation,
    required CalendarPageModel? activePage,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openMobileConfigSheet,
                icon: const Icon(Icons.tune),
                label: const Text('Settings'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openMobileInfoSheet(
                  request: request,
                  pages: pages,
                  previewOrientation: previewOrientation,
                  activePage: activePage,
                ),
                icon: const Icon(Icons.info_outline),
                label: const Text('Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMobileConfigSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        Future<void> openAndClose(Future<void> Function() openSheet) async {
          Navigator.of(sheetContext).pop();
          await Future<void>.delayed(const Duration(milliseconds: 120));
          if (!mounted) {
            return;
          }
          await openSheet();
        }

        return FractionallySizedBox(
          heightFactor: 0.42,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: CalendarGenerationSettingsLauncherCard(
              onGeneralTap: () => openAndClose(_openGeneralSettingsSheet),
              onLayoutTap: () => openAndClose(_openLayoutSettingsSheet),
              onVisibilityTap: () => openAndClose(_openVisibilitySettingsSheet),
              onThemeTap: () => openAndClose(_openThemeSettingsSheet),
              onBackgroundTap: () => openAndClose(_openBackgroundSettingsSheet),
              onTemplateTap: () => openAndClose(_openTemplateSettingsSheet),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMobileInfoSheet({
    required CalendarGenerationRequest request,
    required List<CalendarPageModel> pages,
    required CalendarPageOrientation previewOrientation,
    required CalendarPageModel? activePage,
  }) async {
    final bloc = context.read<CalendarGenerationBloc>();
    var localPreviewOrientation = previewOrientation;
    var localSyncPreviewOrientationToExport = _syncPreviewOrientationToExport;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return BlocBuilder<
                  CalendarGenerationBloc,
                  CalendarGenerationState
                >(
                  bloc: bloc,
                  builder: (context, state) {
                    CalendarGenerationLoaded? loaded;
                    if (state is CalendarGenerationLoaded) {
                      loaded = state;
                    }
                    final currentRequest = loaded?.request ?? request;
                    final currentPages = loaded?.pages ?? pages;
                    final safePreviewPage = _previewPage.clamp(
                      0,
                      (currentPages.length - 1).clamp(0, 9999),
                    );
                    final currentActivePage = currentPages.isEmpty
                        ? activePage
                        : currentPages[safePreviewPage];

                    if (localSyncPreviewOrientationToExport) {
                      localPreviewOrientation = currentRequest.pageOrientation;
                    }

                    return SingleChildScrollView(
                      child: CalendarGenerationPreviewSummaryCard(
                        request: currentRequest,
                        pages: currentPages,
                        previewOrientation: localPreviewOrientation,
                        activePage: currentActivePage,
                        syncPreviewOrientationToExport:
                            localSyncPreviewOrientationToExport,
                        onPreviewOrientationChanged: (selected) {
                          _onPreviewOrientationChanged(selected);
                          setModalState(() {
                            localPreviewOrientation = selected;
                          });
                        },
                        onSyncPreviewOrientationChanged: (value) {
                          _onSyncPreviewOrientationChanged(
                            value,
                            currentRequest,
                          );
                          setModalState(() {
                            localSyncPreviewOrientationToExport = value;
                            if (value) {
                              localPreviewOrientation =
                                  currentRequest.pageOrientation;
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _onPreviewPageChanged(int index) {
    _updateViewState(() {
      _previewPage = index;
    });
  }

  void _onPreviewOrientationChanged(CalendarPageOrientation selected) {
    if (_syncPreviewOrientationToExport) {
      context.read<CalendarGenerationBloc>().add(
        ChangePageOrientation(selected),
      );
      return;
    }
    _updateViewState(() {
      _previewOrientationOverride = selected;
    });
  }

  void _onSyncPreviewOrientationChanged(
    bool value,
    CalendarGenerationRequest request,
  ) {
    _updateViewState(() {
      _syncPreviewOrientationToExport = value;
    });
    if (!value) {
      return;
    }
    final orientation = _previewOrientationOverride ?? request.pageOrientation;
    _previewOrientationOverride = null;
    context.read<CalendarGenerationBloc>().add(
      ChangePageOrientation(orientation),
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

  void _updateViewState(VoidCallback updater) {
    setState(updater);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

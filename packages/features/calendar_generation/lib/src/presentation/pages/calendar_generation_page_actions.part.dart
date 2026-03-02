part of 'calendar_generation_page.dart';

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
    fontWeightValue: element.fontWeightValue,
    italic: element.italic,
    letterSpacing: element.letterSpacing,
    backgroundColorValue: element.backgroundColorValue,
    shadowColorValue: element.shadowColorValue,
    shadowBlur: element.shadowBlur,
    shadowOffsetX: element.shadowOffsetX,
    shadowOffsetY: element.shadowOffsetY,
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
    fontWeightValue: item.fontWeightValue,
    italic: item.italic,
    letterSpacing: item.letterSpacing,
    backgroundColorValue: item.backgroundColorValue,
    shadowColorValue: item.shadowColorValue,
    shadowBlur: item.shadowBlur,
    shadowOffsetX: item.shadowOffsetX,
    shadowOffsetY: item.shadowOffsetY,
    baseSize: item.baseSize,
  );
}

extension _CalendarGenerationActionsX on _CalendarGenerationViewState {
  void _onQuickActionSelected(CalendarGenerationQuickAction action) {
    switch (action) {
      case CalendarGenerationQuickAction.sharePdf:
        _exportPdf();
        break;
      case CalendarGenerationQuickAction.savePdf:
        _savePdfToDevice();
        break;
      case CalendarGenerationQuickAction.shareImages:
        _exportImages();
        break;
      case CalendarGenerationQuickAction.saveImages:
        _saveImagesToDevice();
        break;
      case CalendarGenerationQuickAction.printPdf:
        _printPdf();
        break;
    }
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

  Future<void> _openLayoutEditor() async {
    final state = context.read<CalendarGenerationBloc>().state;
    if (state is! CalendarGenerationLoaded) {
      _showSnack('Calendar preview is still loading.');
      return;
    }
    if (state.pages.isEmpty) {
      _showSnack('No pages available for layout editing.');
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
      _showSnack('No pages available for layout editing.');
      return;
    }

    if (previewOrientation != state.request.pageOrientation) {
      context.read<CalendarGenerationBloc>().add(
        ChangePageOrientation(previewOrientation),
      );
    }

    final result = await Navigator.of(context).push<CalendarLayoutEditorResult>(
      MaterialPageRoute<CalendarLayoutEditorResult>(
        fullscreenDialog: true,
        builder: (context) => CalendarLayoutEditorPage(
          request: editorRequest,
          pages: editorPages,
          initialPageIndex: _previewPage,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    context.read<CalendarGenerationBloc>().add(
      UpdateCalendarPreviewTheme(result.theme),
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

    _updateViewState(() {
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
        _updateViewState(() {
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
}

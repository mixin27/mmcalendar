part of 'calendar_generation_page.dart';

extension _CalendarGenerationTemplateX on _CalendarGenerationViewState {
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
    _updateViewState(() {
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
      _updateViewState(() {
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
    _updateViewState(() {
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
}

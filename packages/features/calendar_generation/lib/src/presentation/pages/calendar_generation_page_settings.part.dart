part of 'calendar_generation_page.dart';

extension _CalendarGenerationSettingsSheetX on _CalendarGenerationViewState {
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
        presetColors: _CalendarGenerationViewState._presetColors,
      ),
    );
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
}

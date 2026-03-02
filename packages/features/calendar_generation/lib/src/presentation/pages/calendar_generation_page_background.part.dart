part of 'calendar_generation_page.dart';

extension _CalendarGenerationBackgroundX on _CalendarGenerationViewState {
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
    _updateViewState(() {
      _imageOverrideMonth = selectedMonth;
    });
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

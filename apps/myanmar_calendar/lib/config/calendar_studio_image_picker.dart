import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Gallery and camera on phones via `image_picker`; files everywhere via the
/// Studio default picker. Desktop and web have no system camera UI, so they
/// only offer files.
class AppCalendarStudioImagePicker implements CalendarStudioImagePicker {
  AppCalendarStudioImagePicker();

  final _picker = ImagePicker();
  static const _files = CalendarStudioFileImagePicker();

  static bool get _isPhone =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  List<CalendarStudioImageSource> get sources => [
    if (_isPhone) ...[
      CalendarStudioImageSource.gallery,
      CalendarStudioImageSource.camera,
    ],
    CalendarStudioImageSource.files,
  ];

  @override
  Future<CalendarStudioPickedImage?> pick(
    CalendarStudioImageSource source, {
    required int maxDimension,
  }) async {
    final imageSource = switch (source) {
      CalendarStudioImageSource.gallery => ImageSource.gallery,
      CalendarStudioImageSource.camera => ImageSource.camera,
      CalendarStudioImageSource.files => null,
    };
    if (imageSource == null) {
      return _files.pick(source, maxDimension: maxDimension);
    }
    // Native downscale on phones; Studio still enforces the limit after.
    final file = await _picker.pickImage(
      source: imageSource,
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: 92,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    return CalendarStudioPickedImage(
      name: file.name,
      bytes: await file.readAsBytes(),
      mimeType: file.mimeType,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'app_overlays.dart';

/// Picks any colour in an app sheet: a saturation/brightness area with a hue
/// slider. Resolves to the colour on Done, or null when dismissed.
Future<Color?> showAppColorPicker({
  required BuildContext context,
  required String title,
  required Color initial,
  String cancelLabel = 'Cancel',
  required String doneLabel,
}) {
  final picked = ValueNotifier<Color>(initial);
  late BuildContext sheet;
  return showAppSheet<Color>(
    context: context,
    title: title,
    cancelLabel: cancelLabel,
    doneLabel: doneLabel,
    onDone: () => Navigator.of(sheet).pop(picked.value),
    builder: (context) {
      sheet = context;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: ValueListenableBuilder<Color>(
          valueListenable: picked,
          builder: (context, color, _) => ColorPicker(
            pickerColor: color,
            onColorChanged: (c) => picked.value = c,
            enableAlpha: false,
            labelTypes: const [],
            displayThumbColor: true,
            pickerAreaHeightPercent: .62,
            pickerAreaBorderRadius: BorderRadius.circular(12),
            portraitOnly: true,
          ),
        ),
      );
    },
  ).whenComplete(picked.dispose);
}

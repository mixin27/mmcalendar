import 'package:flutter/material.dart';

import 'color_picker_tile.dart';

// Custom Colors Editor Dialog Widget
class CustomColorsEditorDialog extends StatefulWidget {
  final ColorScheme initialColors;
  final void Function(ColorScheme colorSchema) onSave;

  const CustomColorsEditorDialog({
    super.key,
    required this.initialColors,
    required this.onSave,
  });

  @override
  State<CustomColorsEditorDialog> createState() =>
      _CustomColorsEditorDialogState();
}

class _CustomColorsEditorDialogState extends State<CustomColorsEditorDialog> {
  late ColorScheme _colors;

  void _updateColor(ColorScheme newColorScheme) {
    setState(() {
      _colors = newColorScheme;
    });
  }

  @override
  void initState() {
    super.initState();
    _colors = widget.initialColors;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.palette,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom Colors',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Personalize your theme',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Color pickers
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ColorPickerTile(
                      title: 'Primary Color',
                      subtitle: 'Main brand color',
                      color: _colors.primary,
                      onColorChanged: (color) {
                        _updateColor(_colors.copyWith(primary: color));
                      },
                    ),
                    const SizedBox(height: 12),

                    ColorPickerTile(
                      title: 'On Primary Color',
                      subtitle: 'On main brand color',
                      color: _colors.onPrimary,
                      onColorChanged: (color) {
                        _updateColor(_colors.copyWith(onPrimary: color));
                      },
                    ),
                    const SizedBox(height: 12),

                    ColorPickerTile(
                      title: 'Secondary Color',
                      subtitle: 'Accent elements',
                      color: _colors.secondary,
                      onColorChanged: (color) {
                        _updateColor(_colors.copyWith(secondary: color));
                      },
                    ),
                    const SizedBox(height: 12),

                    ColorPickerTile(
                      title: 'On Secondary Color',
                      subtitle: 'On accent elements',
                      color: _colors.onSecondary,
                      onColorChanged: (color) {
                        _updateColor(_colors.copyWith(onSecondary: color));
                      },
                    ),
                    const SizedBox(height: 12),

                    ColorPickerTile(
                      title: 'Tertiary Color',
                      subtitle: 'Additional accent',
                      color: _colors.tertiary,
                      onColorChanged: (color) {
                        _updateColor(_colors.copyWith(tertiary: color));
                      },
                    ),
                    const SizedBox(height: 12),

                    ColorPickerTile(
                      title: 'On Tertiary Color',
                      subtitle: 'On additional accent',
                      color: _colors.onTertiary,
                      onColorChanged: (color) {
                        _updateColor(_colors.copyWith(onTertiary: color));
                      },
                    ),
                    const SizedBox(height: 12),

                    ColorPickerTile(
                      title: 'Error Color',
                      subtitle: 'Error messages',
                      color: _colors.error,
                      onColorChanged: (color) {
                        _updateColor(_colors.copyWith(error: color));
                      },
                    ),
                    const SizedBox(height: 12),

                    ColorPickerTile(
                      title: 'On Error Color',
                      subtitle: 'On error messages',
                      color: _colors.onError,
                      onColorChanged: (color) {
                        _updateColor(_colors.copyWith(onError: color));
                      },
                    ),
                    const SizedBox(height: 12),

                    ColorPickerTile(
                      title: 'Surface Color',
                      subtitle: 'Background surfaces',
                      color: _colors.surface,
                      onColorChanged: (color) {
                        _updateColor(_colors.copyWith(surface: color));
                      },
                    ),
                    const SizedBox(height: 12),

                    ColorPickerTile(
                      title: 'On Surface Color',
                      subtitle: 'On background surfaces',
                      color: _colors.onSurface,
                      onColorChanged: (color) {
                        _updateColor(_colors.copyWith(onSurface: color));
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      widget.onSave(_colors);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

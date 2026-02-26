import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings/settings.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// Custom Colors Editor Dialog
void showCustomColorsEditor(BuildContext context, AppSettingsEntity settings) {
  showDialog(
    context: context,
    builder: (dialogContext) => CustomColorsEditorDialog(
      initialColors: settings.customColors ?? AppColorSchemes.modernLight,
      onSave: (colorSchema) {
        context.read<SettingsBloc>().add(UpdateCustomColors(colorSchema));
        Navigator.pop(dialogContext);
      },
    ),
  );
}

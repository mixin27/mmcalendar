import 'package:flutter/material.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' hide ContextExtension;

/// A borderless text field that sits in an [AppGroup] like a row.
class FormFieldRow extends StatelessWidget {
  const FormFieldRow({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.maxLines = 1,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.isClear ? 14 : 16,
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
              child: Icon(icon, size: 20, color: t.secondaryLabel),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              minLines: 1,
              maxLines: maxLines,
              textInputAction: maxLines > 1
                  ? TextInputAction.newline
                  : TextInputAction.next,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: TextStyle(fontSize: 16, color: t.label),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: t.tertiaryLabel),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

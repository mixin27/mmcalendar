import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// A bottom sheet with a title.
///
/// Clear: a grabber and a "Cancel · Title · Done" header. Material: a drag
/// handle, the title on the left and [doneLabel] as a text button.
/// Returns what [builder]'s content pops, or null when dismissed.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  String cancelLabel = 'Cancel',
  String? doneLabel,
  VoidCallback? onDone,
  bool expand = false,
}) {
  final t = context.tokens;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: !t.isClear,
    builder: (sheetContext) {
      final header = t.isClear
          ? Column(
              children: [
                Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(top: 6, bottom: 4),
                  decoration: BoxDecoration(
                    color: t.tertiaryLabel,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 88,
                        child: TextButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(cancelLabel),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            color: t.label,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 88,
                        child: doneLabel == null
                            ? null
                            : TextButton(
                                onPressed: onDone,
                                child: Text(
                                  doneLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                  if (doneLabel != null)
                    TextButton(onPressed: onDone, child: Text(doneLabel)),
                ],
              ),
            );
      final body = Builder(builder: builder);
      return Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          expand ? Expanded(child: body) : Flexible(child: body),
        ],
      );
    },
  );
}

/// A yes/no question: an iOS alert in Clear, a Material dialog otherwise.
/// Resolves to true only when [confirmLabel] was chosen.
Future<bool> showAppConfirm({
  required BuildContext context,
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final t = context.tokens;
  final result = t.isClear
      ? await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(title),
            content: message == null ? null : Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(cancelLabel),
              ),
              CupertinoDialogAction(
                isDefaultAction: !destructive,
                isDestructiveAction: destructive,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        )
      : await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: message == null ? null : Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(cancelLabel),
              ),
              TextButton(
                style: destructive
                    ? TextButton.styleFrom(foregroundColor: t.holiday)
                    : null,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        );
  return result ?? false;
}

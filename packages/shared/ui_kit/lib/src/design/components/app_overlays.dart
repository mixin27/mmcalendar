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

/// Asks for one line of text (a name): an iOS alert with a text field in
/// Clear, a Material dialog otherwise. Resolves to the trimmed text when
/// [confirmLabel] was chosen and it isn't empty, else null.
Future<String?> showAppPrompt({
  required BuildContext context,
  required String title,
  String? message,
  String initial = '',
  String? placeholder,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
}) async {
  final t = context.tokens;
  final controller = TextEditingController(text: initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: initial.length);
  void done(BuildContext dialogContext) {
    final text = controller.text.trim();
    Navigator.of(dialogContext).pop(text.isEmpty ? null : text);
  }

  final result = t.isClear
      ? await showCupertinoDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(title),
            content: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(message),
                    ),
                  CupertinoTextField(
                    controller: controller,
                    autofocus: true,
                    placeholder: placeholder,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => done(dialogContext),
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(cancelLabel),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => done(dialogContext),
                child: Text(confirmLabel),
              ),
            ],
          ),
        )
      : await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(message),
                  ),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: placeholder),
                  onSubmitted: (_) => done(dialogContext),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(cancelLabel),
              ),
              TextButton(
                onPressed: () => done(dialogContext),
                child: Text(confirmLabel),
              ),
            ],
          ),
        );
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  return result;
}

/// A list of actions from the bottom: an iOS action sheet in Clear, a
/// Material bottom sheet list otherwise. Runs the chosen action.
Future<void> showAppActionSheet({
  required BuildContext context,
  String? title,
  String? message,
  required List<AppMenuAction> actions,
  String cancelLabel = 'Cancel',
}) async {
  final t = context.tokens;
  final chosen = t.isClear
      ? await showCupertinoModalPopup<AppMenuAction>(
          context: context,
          builder: (sheetContext) => CupertinoActionSheet(
            title: title == null ? null : Text(title),
            message: message == null ? null : Text(message),
            actions: [
              for (final action in actions)
                CupertinoActionSheetAction(
                  isDestructiveAction: action.destructive,
                  onPressed: () => Navigator.of(sheetContext).pop(action),
                  child: Text(action.label),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(cancelLabel),
            ),
          ),
        )
      : await showModalBottomSheet<AppMenuAction>(
          context: context,
          showDragHandle: true,
          useSafeArea: true,
          builder: (sheetContext) => SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(
                      title,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                for (final action in actions)
                  ListTile(
                    leading: action.icon == null ? null : Icon(action.icon),
                    iconColor: action.destructive ? t.holiday : null,
                    textColor: action.destructive ? t.holiday : null,
                    title: Text(action.label),
                    onTap: () => Navigator.of(sheetContext).pop(action),
                  ),
              ],
            ),
          ),
        );
  chosen?.onSelected();
}

/// One choice in an [AppMenuButton].
class AppMenuAction {
  const AppMenuAction({
    required this.label,
    required this.onSelected,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onSelected;
  final bool destructive;
}

/// A "more" button whose menu follows the app style.
///
/// Clear: an iOS pull-down menu, label on the left and icon on the right,
/// with a thick gap between [groups]. Material: a Material 3 menu with
/// leading icons and a divider between [groups].
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({
    super.key,
    required this.groups,
    this.tooltip = 'More',
    this.icon,
  });

  final List<List<AppMenuAction>> groups;
  final String tooltip;

  /// Defaults to ⋯ in Clear and ⋮ in Material.
  final IconData? icon;

  static const double _clearWidth = 250;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final clear = t.isClear;
    return MenuAnchor(
      style: clear
          ? MenuStyle(
              backgroundColor: WidgetStatePropertyAll(t.surfaceRaised),
              surfaceTintColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
              elevation: const WidgetStatePropertyAll(16),
              shadowColor: WidgetStatePropertyAll(
                Colors.black.withValues(alpha: .45),
              ),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            )
          : null,
      menuChildren: [
        for (var g = 0; g < groups.length; g++) ...[
          if (g > 0)
            clear
                ? Container(width: _clearWidth, height: 8, color: t.fill)
                : const Divider(height: 9),
          for (var i = 0; i < groups[g].length; i++) ...[
            if (clear && i > 0)
              Container(width: _clearWidth, height: .5, color: t.separator),
            clear
                ? _clearItem(context, groups[g][i])
                : _materialItem(context, groups[g][i]),
          ],
        ],
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: tooltip,
        icon: Icon(icon ?? (clear ? Icons.more_horiz : Icons.more_vert)),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  Widget _clearItem(BuildContext context, AppMenuAction action) {
    final t = context.tokens;
    final color = action.destructive ? t.holiday : t.label;
    return MenuItemButton(
      onPressed: action.onSelected,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(_clearWidth, 44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        overlayColor: WidgetStatePropertyAll(t.fill),
        foregroundColor: WidgetStatePropertyAll(color),
        iconColor: WidgetStatePropertyAll(color),
      ),
      child: SizedBox(
        width: _clearWidth - 32,
        child: Row(
          children: [
            Expanded(
              child: Text(
                action.label,
                style: TextStyle(fontSize: 16, color: color),
              ),
            ),
            if (action.icon != null) Icon(action.icon, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _materialItem(BuildContext context, AppMenuAction action) {
    final color = action.destructive ? context.tokens.holiday : null;
    return MenuItemButton(
      onPressed: action.onSelected,
      leadingIcon: action.icon == null ? null : Icon(action.icon),
      style: color == null
          ? null
          : ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(color),
              iconColor: WidgetStatePropertyAll(color),
            ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 140),
        child: Text(action.label),
      ),
    );
  }
}

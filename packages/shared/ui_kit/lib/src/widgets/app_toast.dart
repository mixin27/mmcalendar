import 'package:flutter/material.dart';

enum AppToastKind { info, success, error }

/// Short, self-dismissing messages with an optional action and a countdown
/// ring, like Gmail's "Undo" after archiving.
///
/// Flutter keeps snackbars that have an action on screen until they're
/// tapped (`SnackBar.persist` defaults to `action != null`). These toasts
/// always time out, except when a screen reader is on, where a timed message
/// could disappear before it is read.
extension AppToastContext on BuildContext {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showToast(
    String message, {
    AppToastKind kind = AppToastKind.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.of(this)..hideCurrentSnackBar();
    final screenReader = MediaQuery.maybeAccessibleNavigationOf(this) ?? false;
    final time =
        duration ??
        switch ((kind, actionLabel != null)) {
          (AppToastKind.error, _) => const Duration(seconds: 6),
          (_, true) => const Duration(seconds: 5),
          _ => const Duration(seconds: 3),
        };
    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: time,
        persist: screenReader,
        dismissDirection: DismissDirection.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        content: AppToastContent(
          message: message,
          kind: kind,
          duration: time,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  messenger.hideCurrentSnackBar(
                    reason: SnackBarClosedReason.action,
                  );
                  onAction();
                },
        ),
      ),
    );
  }
}

/// Toast body: icon, message, then the action (if any) and a ring that
/// drains over [duration] with the seconds left inside.
class AppToastContent extends StatefulWidget {
  const AppToastContent({
    required this.message,
    required this.kind,
    required this.duration,
    this.actionLabel,
    this.onAction,
    super.key,
  });
  final String message;
  final AppToastKind kind;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<AppToastContent> createState() => _AppToastContentState();
}

class _AppToastContentState extends State<AppToastContent>
    with SingleTickerProviderStateMixin {
  late final _countdown = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  )..reverse();

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onToast = scheme.onInverseSurface;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final icon = switch (widget.kind) {
      AppToastKind.error => Icons.error_outline,
      AppToastKind.success => Icons.check_circle_outline,
      AppToastKind.info => null,
    };
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: widget.kind == AppToastKind.error
                ? scheme.errorContainer
                : onToast,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(widget.message),
          ),
        ),
        if (widget.actionLabel != null)
          TextButton(
            onPressed: widget.onAction,
            style: TextButton.styleFrom(foregroundColor: scheme.inversePrimary),
            child: Text(widget.actionLabel!),
          ),
        SizedBox.square(
          dimension: 36,
          child: AnimatedBuilder(
            animation: _countdown,
            builder: (context, _) {
              final remaining =
                  (_countdown.value * widget.duration.inMilliseconds / 1000)
                      .ceil();
              return Semantics(
                label: '$remaining seconds left',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        value: reduceMotion ? 1 : _countdown.value,
                        strokeWidth: 2.2,
                        color: onToast,
                        backgroundColor: onToast.withValues(alpha: .2),
                      ),
                    ),
                    Text(
                      '$remaining',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: onToast,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

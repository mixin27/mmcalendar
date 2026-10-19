import 'package:flutter/material.dart';

enum StudioToastKind { info, error }

/// Studio's self-dismissing toast with a countdown ring (the app has the same
/// pattern in `shared_ui_kit`'s `AppToast`; Studio keeps its own copy so the
/// package stays independent).
///
/// Snackbars with an action persist by default in Flutter; these always time
/// out, except while a screen reader is on.
extension StudioToast on ScaffoldMessengerState {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> toast(
    String message, {
    StudioToastKind kind = StudioToastKind.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    hideCurrentSnackBar();
    final screenReader =
        MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
    final time =
        duration ??
        (kind == StudioToastKind.error
            ? const Duration(seconds: 6)
            : actionLabel != null
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3));
    return showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: time,
        persist: screenReader,
        dismissDirection: DismissDirection.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        content: _StudioToastContent(
          message: message,
          kind: kind,
          duration: time,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  hideCurrentSnackBar(reason: SnackBarClosedReason.action);
                  onAction();
                },
        ),
      ),
    );
  }
}

class _StudioToastContent extends StatefulWidget {
  const _StudioToastContent({
    required this.message,
    required this.kind,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final StudioToastKind kind;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_StudioToastContent> createState() => _StudioToastContentState();
}

class _StudioToastContentState extends State<_StudioToastContent>
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
    return Row(
      children: [
        if (widget.kind == StudioToastKind.error) ...[
          Icon(Icons.error_outline, size: 20, color: scheme.errorContainer),
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

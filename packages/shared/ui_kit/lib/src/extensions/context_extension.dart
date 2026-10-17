import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';
import '../widgets/app_toast.dart';

extension ContextExtension on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // MediaQuery
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  // Screen breakpoints
  bool get isMobile => screenWidth < ResponsiveUtils.tabletBreakpoint;
  bool get isTablet =>
      screenWidth >= ResponsiveUtils.tabletBreakpoint &&
      screenWidth < ResponsiveUtils.desktopBreakpoint;
  bool get isDesktop => screenWidth >= ResponsiveUtils.desktopBreakpoint;

  // Navigation
  NavigatorState get navigator => Navigator.of(this);

  void pop<T>([T? result]) => navigator.pop(result);

  Future<T?> push<T>(Route<T> route) => navigator.push(route);

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      navigator.pushNamed(routeName, arguments: arguments);

  Future<T?> pushReplacement<T, TO>(Route<T> route, {TO? result}) =>
      navigator.pushReplacement(route, result: result);

  Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) => navigator.pushReplacementNamed(
    routeName,
    result: result,
    arguments: arguments,
  );

  // Snackbar: all go through the self-dismissing toast (see app_toast.dart).
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) => showToast(
    message,
    duration: duration,
    actionLabel: action?.label,
    onAction: action?.onPressed,
  );

  void showErrorSnackBar(String message) =>
      showToast(message, kind: AppToastKind.error);

  void showSuccessSnackBar(String message) =>
      showToast(message, kind: AppToastKind.success);

  // Dialog
  Future<T?> showAlertDialog<T>({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
  }) {
    return showDialog<T>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancelText),
            ),
          if (confirmText != null)
            TextButton(
              onPressed: () {
                onConfirm?.call();
                Navigator.of(context).pop();
              },
              child: Text(confirmText),
            ),
        ],
      ),
    );
  }

  // Focus
  void unfocus() => FocusScope.of(this).unfocus();

  void requestFocus(FocusNode focusNode) =>
      FocusScope.of(this).requestFocus(focusNode);
}

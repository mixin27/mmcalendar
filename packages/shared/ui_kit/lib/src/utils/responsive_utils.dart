import 'package:flutter/material.dart';

class ResponsiveUtils {
  /// Widths at and above this are tablet layouts.
  static const double tabletBreakpoint = 600;

  /// Widths at and above this are desktop layouts.
  static const double desktopBreakpoint = 1024;

  static double getScreenSize(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < tabletBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }
}

class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    if (screenSize < ResponsiveUtils.tabletBreakpoint) {
      return mobile;
    } else if (screenSize < ResponsiveUtils.desktopBreakpoint) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }
}

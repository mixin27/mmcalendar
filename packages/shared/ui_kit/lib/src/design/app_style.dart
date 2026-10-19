import 'package:flutter/foundation.dart';

/// Which design system draws the app's chrome.
///
/// Colours, type, content and every screen's features are shared; only
/// bars, lists, controls, sheets and dialogs change.
enum AppStyle {
  /// Material on Android, Windows and Linux; Clear on iOS, macOS and web.
  automatic,

  /// iOS-like: inset grouped lists, frosted tab bar, bold large titles.
  clear,

  /// Android: full-width lists, pill navigation bar, M3 controls.
  material;

  static AppStyle fromName(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => automatic);

  /// The concrete style to draw: never [automatic].
  AppStyle resolve({TargetPlatform? platform, bool isWeb = kIsWeb}) {
    if (this != automatic) return this;
    if (isWeb) return clear;
    return switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => clear,
      _ => material,
    };
  }
}

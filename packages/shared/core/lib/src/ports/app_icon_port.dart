/// App icon option metadata used in settings UI.
class AppIconOption {
  final String id;
  final String label;

  const AppIconOption({required this.id, required this.label});
}

/// SDK-agnostic app icon contract.
///
/// Implementations can use platform channels (Android/iOS) or no-op behavior
/// on unsupported platforms.
abstract interface class AppIconPort {
  List<AppIconOption> get availableIcons;

  Future<bool> isSupported();

  Future<String> getCurrentIcon();

  Future<bool> setIcon(String iconId);
}

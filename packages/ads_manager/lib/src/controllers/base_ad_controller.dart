abstract class BaseAdController {
  bool get isLoaded;
  Future<void> load();
  Future<void> show();
  void dispose();
}

import 'package:ads_manager/src/controllers/app_open_ad_controller.dart';

class DummyAppOpenAdController implements AppOpenAdController {
  @override
  void dispose() {}

  @override
  bool get isEnabled => false;

  @override
  bool get isLoaded => false;

  @override
  Future<void> load() async {}

  @override
  Future<void> show() async {}
}

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'base_ad_controller.dart';

abstract class NativeAdController extends BaseAdController {
  /// Return a widget that renders the native ad
  Widget get widget;

  Future<void> loadWithTemplate({
    required NativeTemplateStyle nativeTemplateStyle,
  });
}

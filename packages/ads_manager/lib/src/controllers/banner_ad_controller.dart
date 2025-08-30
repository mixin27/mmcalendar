import 'package:flutter/widgets.dart';
import 'base_ad_controller.dart';

abstract class BannerAdController extends BaseAdController {
  /// Widget to embed into the tree. Platform-specific adapter returns appropriate Widget.
  Widget get widget;
}

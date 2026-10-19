import 'package:flutter/services.dart';
import 'package:shared_core/shared_core.dart';

/// The icons in Settings › App icon, in order (tool/app_icons_test.dart
/// draws them). Ids are stable: older ones keep their Android alias and
/// iOS icon set and now show new artwork, so an update never removes the
/// launcher entry someone chose.
const appIconOptions = <AppIconOption>[
  AppIconOption(id: 'default', label: 'Night'),
  AppIconOption(id: 'dawn', label: 'Dawn'),
  AppIconOption(id: 'forest', label: 'Jade'),
  AppIconOption(id: 'traditional_myanmar', label: 'Lacquer'),
  AppIconOption(id: 'minimal_flat', label: 'Paper'),
  AppIconOption(id: 'premium_dark', label: 'Midnight'),
  AppIconOption(id: 'thingyan', label: 'Thingyan'),
  AppIconOption(id: 'moon', label: 'Dusk'),
  AppIconOption(id: 'pagoda', label: 'Pagoda'),
  AppIconOption(id: 'classic', label: 'Classic'),
];

class MethodChannelAppIconPort implements AppIconPort {
  static const MethodChannel _channel = MethodChannel(
    'dev.mixin27.mmcalendar/app_icon',
  );

  @override
  List<AppIconOption> get availableIcons => appIconOptions;

  @override
  Future<String> getCurrentIcon() async {
    try {
      final value = await _channel.invokeMethod<String>('getCurrentIcon');
      return value ?? 'default';
    } catch (_) {
      return 'default';
    }
  }

  @override
  Future<bool> isSupported() async {
    try {
      final value = await _channel.invokeMethod<bool>('isSupported');
      return value ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> setIcon(String iconId) async {
    try {
      final value = await _channel.invokeMethod<bool>(
        'setAppIcon',
        <String, dynamic>{'iconId': iconId},
      );
      if (value != true) {
        return false;
      }
      return await getCurrentIcon() == iconId;
    } on PlatformException catch (error) {
      throw AppIconException(
        code: error.code,
        message: error.message ?? 'Failed to switch app icon.',
      );
    } on MissingPluginException {
      throw const AppIconException(
        code: 'channel_unavailable',
        message: 'App icon switching is unavailable on this platform.',
      );
    }
  }
}

class NoopAppIconPort implements AppIconPort {
  @override
  List<AppIconOption> get availableIcons => appIconOptions;

  @override
  Future<String> getCurrentIcon() async => 'default';

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<bool> setIcon(String iconId) async => false;
}

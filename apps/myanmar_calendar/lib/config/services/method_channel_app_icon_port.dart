import 'package:flutter/services.dart';
import 'package:shared_core/shared_core.dart';

class MethodChannelAppIconPort implements AppIconPort {
  static const MethodChannel _channel = MethodChannel(
    'dev.mixin27.mmcalendar/app_icon',
  );

  @override
  List<AppIconOption> get availableIcons => const <AppIconOption>[
    AppIconOption(id: 'default', label: 'Default'),
    AppIconOption(id: 'moon', label: 'Moon'),
    AppIconOption(id: 'forest', label: 'Forest'),
    AppIconOption(id: 'minimal_flat', label: 'Minimal Flat'),
    AppIconOption(id: 'premium_dark', label: 'Premium Dark'),
    AppIconOption(
      id: 'traditional_myanmar',
      label: 'Traditional Myanmar Motif',
    ),
  ];

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
      return value ?? false;
    } catch (_) {
      return false;
    }
  }
}

class NoopAppIconPort implements AppIconPort {
  @override
  List<AppIconOption> get availableIcons => const <AppIconOption>[
    AppIconOption(id: 'default', label: 'Default'),
    AppIconOption(id: 'moon', label: 'Moon'),
    AppIconOption(id: 'forest', label: 'Forest'),
    AppIconOption(id: 'minimal_flat', label: 'Minimal Flat'),
    AppIconOption(id: 'premium_dark', label: 'Premium Dark'),
    AppIconOption(
      id: 'traditional_myanmar',
      label: 'Traditional Myanmar Motif',
    ),
  ];

  @override
  Future<String> getCurrentIcon() async => 'default';

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<bool> setIcon(String iconId) async => false;
}

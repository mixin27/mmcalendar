import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

/// Firebase-backed holiday config adapter.
///
/// Owns decoding of remote-config JSON payload into a typed map so feature
/// packages remain SDK-agnostic.
class HolidayConfigService implements HolidayConfigPort {
  HolidayConfigService({
    required RemoteConfigPort remoteConfigPort,
    String configKey = 'holidays_config',
  }) : _remoteConfigPort = remoteConfigPort,
       _configKey = configKey;

  final RemoteConfigPort _remoteConfigPort;
  final String _configKey;

  @override
  Map<String, dynamic> getHolidayConfig() {
    final String jsonString = _remoteConfigPort.getString(_configKey);
    if (jsonString.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final Object? decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (error) {
      debugPrint('Failed to decode holiday config: $error');
      return <String, dynamic>{};
    }
  }
}

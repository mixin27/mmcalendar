import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_app_update/integrations_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_core/shared_core.dart';

class _FakeRemoteConfigPort implements RemoteConfigPort {
  _FakeRemoteConfigPort(this._values);

  final Map<String, Object> _values;

  @override
  Future<RemoteFetchResult> fetchAndActivate() async =>
      RemoteFetchResult.noChange;

  @override
  Map<String, Object> getAll() => _values;

  @override
  bool getBool(String key) => _values[key] as bool? ?? false;

  @override
  double getDouble(String key) => _values[key] as double? ?? 0.0;

  @override
  int getInt(String key) => _values[key] as int? ?? 0;

  @override
  String getString(String key) => _values[key] as String? ?? '';

  @override
  Future<void> initialize() async {}
}

void main() {
  final packageInfo = PackageInfo(
    appName: 'MMCalendar',
    packageName: 'dev.mixin27.mmcalendar',
    version: '2.1.5',
    buildNumber: '209',
    buildSignature: '',
  );

  RemoteConfigAppUpdatePort buildPort(Map<String, Object> values) {
    return RemoteConfigAppUpdatePort(
      remoteConfigPort: _FakeRemoteConfigPort(values),
      playStoreId: 'dev.mixin27.mmcalendar',
      packageInfo: packageInfo,
    );
  }

  test('returns unavailable when update checks are disabled', () async {
    final port = buildPort({'app_update_enabled': false});

    final info = await port.checkForUpdate();

    expect(info.availability, AppUpdateAvailability.unavailable);
    expect(info.hasUpdate, isFalse);
  });

  test('returns up to date when current build is latest', () async {
    final port = buildPort({
      'app_update_enabled': true,
      'app_update_latest_build_number': 209,
      'app_update_latest_version': '2.1.5',
      'app_update_min_supported_build_number': 200,
    });

    final info = await port.checkForUpdate();

    expect(info.availability, AppUpdateAvailability.upToDate);
    expect(info.hasUpdate, isFalse);
  });

  test('returns failed when required update has no launch URL', () async {
    final port = buildPort({
      'app_update_enabled': true,
      'app_update_latest_build_number': 300,
      'app_update_latest_version': '3.0.0',
      'app_update_min_supported_build_number': 250,
    });

    final info = await port.checkForUpdate();

    expect(info.availability, AppUpdateAvailability.failed);
    expect(info.title, 'Update configuration error');
  });

  test('returns failed when optional update has no launch URL', () async {
    final port = buildPort({
      'app_update_enabled': true,
      'app_update_latest_build_number': 300,
      'app_update_latest_version': '3.0.0',
      'app_update_min_supported_build_number': 150,
    });

    final info = await port.checkForUpdate();

    expect(info.availability, AppUpdateAvailability.failed);
    expect(info.title, 'Update configuration error');
  });
}

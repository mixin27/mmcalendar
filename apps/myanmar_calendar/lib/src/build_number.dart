import 'package:core/core.dart';

import 'version.dart';

int buildNumber([String version = packageVersion]) {
  final versionSegments = version.split('+');
  if (versionSegments.isEmpty) return 0;
  return int.tryParse(versionSegments.last) ?? 0;
}

String appVersion([String version = packageVersion]) {
  final versionSegments = version.split('+');
  if (versionSegments.isEmpty) return AppConstants.appVersion;
  return versionSegments.first;
}

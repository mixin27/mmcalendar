import 'dart:io';

enum PackageLayer { app, feature, shared, integration, legacy }

final Set<String> _legacyPackageNames = <String>{
  'core',
  'localizations',
  'data',
  'app_remote_config',
  'firebase_analytics_app',
};

final Map<PackageLayer, Set<PackageLayer>> _allowedLayersByLayer =
    <PackageLayer, Set<PackageLayer>>{
      PackageLayer.app: <PackageLayer>{
        PackageLayer.app,
        PackageLayer.feature,
        PackageLayer.shared,
        PackageLayer.integration,
      },
      PackageLayer.feature: <PackageLayer>{
        PackageLayer.feature,
        PackageLayer.shared,
        PackageLayer.integration,
      },
      PackageLayer.shared: <PackageLayer>{
        PackageLayer.shared,
        PackageLayer.legacy,
      },
      PackageLayer.integration: <PackageLayer>{
        PackageLayer.integration,
        PackageLayer.shared,
      },
      PackageLayer.legacy: <PackageLayer>{
        PackageLayer.legacy,
        PackageLayer.integration,
      },
    };

final Map<String, Set<String>> _strictAllowedInternalDependencies =
    <String, Set<String>>{
      // Facades with explicit migration targets.
      'shared_core': <String>{'core'},
      'shared_ui_kit': <String>{'core'},
      'shared_localizations': <String>{'localizations'},
      'data': <String>{'integrations_database'},
      'app_remote_config': <String>{'integrations_firebase'},
    };

/// Explicit feature-to-feature dependency allowlist.
///
/// Any feature dependency not listed here will fail boundary checks.
final Map<String, Set<String>> _allowedFeatureDependencies =
    <String, Set<String>>{
      'calendar': <String>{'events', 'holidays', 'settings'},
      'settings': <String>{'holidays', 'home_widgets', 'promo'},
      'views': <String>{'calendar', 'settings'},
    };

/// Package-level dependency bans by layer.
final Map<PackageLayer, Set<String>> _disallowedInternalDependenciesByLayer =
    <PackageLayer, Set<String>>{
      // Feature code must consume Firebase only via shared domain ports.
      PackageLayer.feature: <String>{'integrations_firebase'},
    };

final Set<PackageLayer> _noLegacyImportLayers = <PackageLayer>{
  PackageLayer.app,
  PackageLayer.feature,
  PackageLayer.integration,
};

/// Source import bans by layer.
final Map<PackageLayer, Set<String>> _disallowedSourceImportsByLayer =
    <PackageLayer, Set<String>>{
      // Keep feature code SDK-agnostic.
      PackageLayer.feature: <String>{'integrations_firebase'},
    };

final RegExp _packageImportPattern = RegExp(
  r"(?:import|export)\s+'package:([a-zA-Z0-9_]+)\/",
);

void main() {
  final Directory root = Directory.current;
  final Map<String, PackageInfo> packages = _discoverWorkspacePackages(root);
  final List<String> errors = <String>[];

  _validateInternalDependencies(packages, errors);
  _validateSourceImports(packages, errors);

  if (errors.isNotEmpty) {
    stderr.writeln('Dependency boundary violations detected:');
    for (final String error in errors..sort()) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Dependency boundary check passed for ${packages.length} workspace packages.',
  );
}

void _validateInternalDependencies(
  Map<String, PackageInfo> packages,
  List<String> errors,
) {
  final Set<String> workspacePackageNames = packages.keys.toSet();

  for (final PackageInfo info in packages.values) {
    final Set<String> internalDependencies = info.dependencies
        .where(workspacePackageNames.contains)
        .toSet();

    final Set<String>? strictAllowedDependencies =
        _strictAllowedInternalDependencies[info.name];
    if (strictAllowedDependencies != null) {
      for (final String dependency in internalDependencies) {
        if (!strictAllowedDependencies.contains(dependency)) {
          errors.add(
            '${info.name} must only depend on '
            '${strictAllowedDependencies.toList()..sort()}, found "$dependency" '
            '(${_relativeToRoot(info.pubspec.path)}).',
          );
        }
      }

      continue;
    }

    for (final String dependencyName in internalDependencies) {
      final PackageInfo dependency = packages[dependencyName]!;
      final Set<PackageLayer> allowedLayers =
          _allowedLayersByLayer[info.layer] ?? <PackageLayer>{};
      final Set<String> disallowedDependencies =
          _disallowedInternalDependenciesByLayer[info.layer] ??
          const <String>{};

      if (!allowedLayers.contains(dependency.layer)) {
        errors.add(
          '${info.name} (${info.layer.name}) cannot depend on $dependencyName '
          '(${dependency.layer.name}) (${_relativeToRoot(info.pubspec.path)}).',
        );
      }

      if (disallowedDependencies.contains(dependencyName)) {
        errors.add(
          '${info.name} (${info.layer.name}) cannot depend on banned package '
          '"$dependencyName" (${_relativeToRoot(info.pubspec.path)}).',
        );
      }

      if (info.layer == PackageLayer.feature &&
          dependency.layer == PackageLayer.feature &&
          dependencyName != info.name) {
        final Set<String> allowedFeatureDependencies =
            _allowedFeatureDependencies[info.name] ?? const <String>{};

        if (!allowedFeatureDependencies.contains(dependencyName)) {
          errors.add(
            '${info.name} (feature) cannot depend on $dependencyName '
            '(feature). Allowed: '
            '${allowedFeatureDependencies.toList()..sort()} '
            '(${_relativeToRoot(info.pubspec.path)}).',
          );
        }
      }

      if (_legacyPackageNames.contains(dependencyName) &&
          info.layer != PackageLayer.legacy &&
          info.layer != PackageLayer.shared) {
        errors.add(
          '${info.name} cannot depend on legacy package "$dependencyName" '
          '(${_relativeToRoot(info.pubspec.path)}).',
        );
      }
    }
  }
}

void _validateSourceImports(
  Map<String, PackageInfo> packages,
  List<String> errors,
) {
  for (final PackageInfo info in packages.values) {
    if (!_noLegacyImportLayers.contains(info.layer)) {
      continue;
    }

    final Directory libDir = Directory('${info.directory.path}/lib');
    if (!libDir.existsSync()) {
      continue;
    }

    for (final FileSystemEntity entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final String content = entity.readAsStringSync();
      final Iterable<RegExpMatch> matches = _packageImportPattern.allMatches(
        content,
      );
      for (final RegExpMatch match in matches) {
        final String importedPackage = match.group(1)!;
        final Set<String> disallowedSourceImports =
            _disallowedSourceImportsByLayer[info.layer] ?? const <String>{};

        if (_legacyPackageNames.contains(importedPackage)) {
          errors.add(
            '${info.name} imports legacy package "$importedPackage" '
            'in ${_relativeToRoot(entity.path)}.',
          );
        }

        if (disallowedSourceImports.contains(importedPackage)) {
          errors.add(
            '${info.name} imports banned package "$importedPackage" '
            'in ${_relativeToRoot(entity.path)}.',
          );
        }

        final PackageInfo? importedPackageInfo = packages[importedPackage];
        if (info.layer == PackageLayer.feature &&
            importedPackageInfo != null &&
            importedPackageInfo.layer == PackageLayer.feature &&
            importedPackage != info.name) {
          final Set<String> allowedFeatureDependencies =
              _allowedFeatureDependencies[info.name] ?? const <String>{};

          if (!allowedFeatureDependencies.contains(importedPackage)) {
            errors.add(
              '${info.name} imports feature package "$importedPackage" '
              'outside allowlist in ${_relativeToRoot(entity.path)}. '
              'Allowed: ${allowedFeatureDependencies.toList()..sort()}.',
            );
          }
        }
      }
    }
  }
}

Map<String, PackageInfo> _discoverWorkspacePackages(Directory root) {
  final Map<String, PackageInfo> packages = <String, PackageInfo>{};
  final List<String> workspaceEntries = _readWorkspaceEntries(root);

  for (final String entry in workspaceEntries) {
    final File pubspec = File('${root.path}/$entry/pubspec.yaml');
    if (!pubspec.existsSync()) {
      stderr.writeln('Skipping workspace entry without pubspec: $entry');
      continue;
    }

    final PackageInfo? info = _readPackageInfo(pubspec);
    if (info == null) {
      continue;
    }

    packages[info.name] = info;
  }

  return packages;
}

List<String> _readWorkspaceEntries(Directory root) {
  final File rootPubspec = File('${root.path}/pubspec.yaml');
  if (!rootPubspec.existsSync()) {
    throw StateError('Root pubspec.yaml not found.');
  }

  final List<String> lines = rootPubspec.readAsLinesSync();
  final List<String> entries = <String>[];
  bool inWorkspaceSection = false;

  for (final String line in lines) {
    final String trimmed = line.trim();
    if (!line.startsWith(' ') && trimmed.isNotEmpty) {
      if (trimmed == 'workspace:') {
        inWorkspaceSection = true;
        continue;
      }

      if (inWorkspaceSection) {
        break;
      }
    }

    if (!inWorkspaceSection) {
      continue;
    }

    final RegExpMatch? entryMatch = RegExp(r'^  - (.+)$').firstMatch(line);
    if (entryMatch != null) {
      entries.add(entryMatch.group(1)!);
    }
  }

  return entries;
}

PackageInfo? _readPackageInfo(File pubspecFile) {
  final List<String> lines = pubspecFile.readAsLinesSync();
  String? packageName;
  final Set<String> dependencies = <String>{};
  bool inDependenciesSection = false;

  for (final String line in lines) {
    final String trimmed = line.trim();

    final RegExpMatch? nameMatch = RegExp(
      r'^name:\s*([A-Za-z0-9_]+)',
    ).firstMatch(trimmed);
    if (nameMatch != null) {
      packageName = nameMatch.group(1);
    }

    if (!line.startsWith(' ') && trimmed.isNotEmpty) {
      inDependenciesSection = trimmed == 'dependencies:';
      continue;
    }

    if (!inDependenciesSection) {
      continue;
    }

    final RegExpMatch? dependencyMatch = RegExp(
      r'^  ([a-zA-Z0-9_]+):',
    ).firstMatch(line);
    if (dependencyMatch != null) {
      dependencies.add(dependencyMatch.group(1)!);
    }
  }

  if (packageName == null) {
    return null;
  }
  final String resolvedPackageName = packageName;

  final Directory packageDir = pubspecFile.parent;
  final PackageLayer layer = _layerForPathAndName(
    packageDir.path,
    resolvedPackageName,
  );

  return PackageInfo(
    name: resolvedPackageName,
    pubspec: pubspecFile,
    directory: packageDir,
    dependencies: dependencies,
    layer: layer,
  );
}

PackageLayer _layerForPathAndName(String path, String packageName) {
  final String normalized = path.replaceAll('\\', '/');
  if (_legacyPackageNames.contains(packageName)) {
    return PackageLayer.legacy;
  }

  if (normalized.contains('/apps/')) {
    return PackageLayer.app;
  }

  if (normalized.contains('/packages/shared/')) {
    return PackageLayer.shared;
  }

  if (normalized.contains('/packages/integrations/')) {
    return PackageLayer.integration;
  }

  if (normalized.contains('/packages/features/')) {
    return PackageLayer.feature;
  }

  return PackageLayer.legacy;
}

String _relativeToRoot(String absolutePath) {
  final String root = Directory.current.path.replaceAll('\\', '/');
  final String normalized = absolutePath.replaceAll('\\', '/');
  if (normalized.startsWith('$root/')) {
    return normalized.substring(root.length + 1);
  }
  if (normalized == root) {
    return '.';
  }
  return normalized;
}

final class PackageInfo {
  const PackageInfo({
    required this.name,
    required this.pubspec,
    required this.directory,
    required this.dependencies,
    required this.layer,
  });

  final String name;
  final File pubspec;
  final Directory directory;
  final Set<String> dependencies;
  final PackageLayer layer;
}

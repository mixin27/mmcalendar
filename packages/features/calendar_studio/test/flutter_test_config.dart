import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Golden tests compare CI goldens only: text renders as blocks. They guard
/// layout, colour and structure; Myanmar glyph shaping is covered by device
/// QA. They're made and checked on macOS: Linux anti-aliasing differs by a
/// few pixels, so scripts/test_all.sh skips the `golden` tag on CI.
Future<void> testExecutable(FutureOr<void> Function() testMain) =>
    AlchemistConfig.runWithConfig(
      config: const AlchemistConfig(
        platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ),
      run: () async => testMain(),
    );

import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Golden tests compare CI goldens only: text renders as blocks, so the
/// images are identical on every machine. They guard layout, colour and
/// structure; Myanmar glyph shaping is covered by device QA.
Future<void> testExecutable(FutureOr<void> Function() testMain) =>
    AlchemistConfig.runWithConfig(
      config: const AlchemistConfig(
        platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ),
      run: () async => testMain(),
    );

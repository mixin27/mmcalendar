#!/usr/bin/env bash

set -euo pipefail

if [[ "${SKIP_PUB_GET:-0}" != "1" ]]; then
  flutter pub get
fi
dart run tool/check_dependency_boundaries.dart

# Run package tests sequentially to avoid Flutter tool cache and build output
# contention in shared workspace paths.
flutter test packages/integrations/database/test
flutter test packages/features/holidays/test

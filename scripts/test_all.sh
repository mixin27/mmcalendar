#!/usr/bin/env bash

set -euo pipefail

flutter pub get
dart run tool/check_dependency_boundaries.dart

# Run package tests sequentially to avoid Flutter tool cache and build output
# contention in shared workspace paths.
flutter test packages/data/test
flutter test packages/features/holidays/test

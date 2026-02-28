#!/usr/bin/env bash

set -euo pipefail

if [[ "${SKIP_PUB_GET:-0}" != "1" ]]; then
  flutter pub get
fi
dart run tool/check_dependency_boundaries.dart
flutter analyze

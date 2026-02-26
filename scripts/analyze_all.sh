#!/usr/bin/env bash

set -euo pipefail

flutter pub get
dart run tool/check_dependency_boundaries.dart
flutter analyze

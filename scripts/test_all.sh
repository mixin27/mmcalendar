#!/usr/bin/env bash
# Runs the tests of every workspace package and app that has tests.

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "${SKIP_PUB_GET:-0}" != "1" ]]; then
  flutter pub get
fi

# One package at a time: parallel runs contend for the Flutter tool cache
# and shared build output in the workspace.
failed=()
for dir in apps/*/ packages/*/*/; do
  dir="${dir%/}"
  # Skip packages without tests (an empty test folder fails flutter test).
  [[ -n "$(find "$dir/test" -name '*_test.dart' -print -quit 2>/dev/null)" ]] || continue
  echo "::group::$dir"
  if ! (cd "$dir" && flutter test); then
    failed+=("$dir")
  fi
  echo "::endgroup::"
done

if (( ${#failed[@]} )); then
  echo "Tests failed in: ${failed[*]}" >&2
  exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "This script now delegates to the unified native setup verify script."
"$ROOT_DIR/scripts/verify_native_mobile_setup.sh" --scope android-icons

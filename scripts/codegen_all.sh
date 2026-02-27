#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT_DIR}"

echo "==> Discovering workspace members that require build_runner..."

workspace_members=()
while IFS= read -r member; do
  workspace_members+=("${member}")
done < <(
  awk '
    $1=="workspace:" {in_workspace=1; next}
    in_workspace && /^[[:space:]]*-[[:space:]]+/ {
      gsub(/^[[:space:]]*-[[:space:]]+/, "", $0);
      print $0;
      next
    }
    in_workspace && $0 !~ /^[[:space:]]/ {exit}
  ' pubspec.yaml
)

if [[ ${#workspace_members[@]} -eq 0 ]]; then
  echo "No workspace members found."
  exit 0
fi

codegen_targets=()
for member in "${workspace_members[@]}"; do
  pubspec="${member}/pubspec.yaml"
  if [[ -f "${pubspec}" ]] && grep -Eq '^[[:space:]]*build_runner:' "${pubspec}"; then
    codegen_targets+=("${member}")
  fi
done

if [[ ${#codegen_targets[@]} -eq 0 ]]; then
  echo "No build_runner targets found."
  exit 0
fi

echo "==> Running build_runner for ${#codegen_targets[@]} target(s)..."
for target in "${codegen_targets[@]}"; do
  echo "--> ${target}"
  (
    cd "${target}"
    dart run build_runner build --delete-conflicting-outputs
  )
done

echo "==> Workspace code generation completed."

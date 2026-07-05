#!/usr/bin/env bash
set -euo pipefail

# Cleans local Dayflow build products that are ignored by git.
#
# Usage:
#   scripts/clean_build_artifacts.sh          # preview
#   scripts/clean_build_artifacts.sh --apply  # delete
#
# Optional:
#   --keep-packages  Keep build/SourcePackages and build/xcode-sourcepackages.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

APPLY=0
KEEP_PACKAGES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --keep-packages) KEEP_PACKAGES=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

paths=(
  "$REPO_ROOT/Dayflow/DerivedData"
  "$REPO_ROOT/Dayflow.dmg"
)

if [[ -d "$REPO_ROOT/build" ]]; then
  for path in "$REPO_ROOT"/build/*; do
    [[ -e "$path" ]] || continue
    if [[ "$KEEP_PACKAGES" -eq 1 ]]; then
      case "$(basename "$path")" in
        SourcePackages|xcode-sourcepackages) continue ;;
      esac
    fi
    paths+=("$path")
  done
fi

echo "Dayflow build artifact cleanup"
echo "Mode: $([[ "$APPLY" -eq 1 ]] && echo delete || echo preview)"
echo

for path in "${paths[@]}"; do
  if [[ ! -e "$path" ]]; then
    continue
  fi

  size=$(du -sh "$path" 2>/dev/null | awk '{print $1}')
  printf '%8s  %s\n' "${size:-?}" "${path#$REPO_ROOT/}"

  if [[ "$APPLY" -eq 1 ]]; then
    rm -rf "$path"
  fi
done

if [[ "$APPLY" -eq 0 ]]; then
  echo
  echo "Preview only. Re-run with --apply to delete these ignored build artifacts."
fi

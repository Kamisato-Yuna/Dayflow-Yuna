#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

APP_PATH="Dayflow/Dayflow"
DOCS_PATH="docs"
PROJECT_PBX="Dayflow/Dayflow.xcodeproj/project.pbxproj"

run_scan() {
  local title="$1"
  local pattern="$2"
  shift 2
  local paths=("$@")

  echo "== ${title} =="
  set +e
  rg -n "$pattern" "${paths[@]}" 2>/dev/null
  local status=$?
  set -e
  if [ "$status" -ne 0 ]; then
    echo "PASS: no matches"
  fi
}

echo "== Liquid Glass final audit =="
echo "Root: $ROOT"
echo

echo "== Bundled media files =="
VIDEO_FILES_OUTPUT="$(find "$APP_PATH" -type f \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v' \))"
VIDEO_FILES_COUNT=$(printf '%s\n' "$VIDEO_FILES_OUTPUT" | sed '/^$/d' | wc -l | tr -d ' ')
if [ "$VIDEO_FILES_COUNT" -eq 0 ]; then
  echo "PASS: no media files in Dayflow/Dayflow"
else
  echo "WARN: $VIDEO_FILES_COUNT media file(s) found"
  if [ -n "$VIDEO_FILES_OUTPUT" ]; then
    echo "$VIDEO_FILES_OUTPUT"
  fi
fi
echo

echo "== Bundled onboarding assets and removed main background references (code path) =="
run_scan "Code references" 'DayflowAnimation\\.mp4|DayflowOnboarding\\.mp4|JournalOnboardingVideo\\.mp4|MainUIBackground\\.imageset|Image\("MainUIBackground"|MainUIBackground' "$APP_PATH" "$PROJECT_PBX"
echo

echo "== Bundled onboarding assets and removed main background references (docs path) =="
run_scan "Docs references" 'DayflowAnimation\\.mp4|DayflowOnboarding\\.mp4|JournalOnboardingVideo\\.mp4|MainUIBackground\\.imageset|MainUIBackground' "$DOCS_PATH"
echo

echo "== macOS 26 Liquid Glass API references (code + docs) =="
run_scan "macOS 26 API references" 'glassEffect|GlassEffect|GlassButtonStyle|GlassProminentButtonStyle|backgroundExtensionEffect|#available\(macOS 26|@available\(macOS 26' "$APP_PATH" "$DOCS_PATH"
echo

echo "== Background residuals to explain (code path) =="
run_scan "Background residuals" 'Color\(red: 0\.98|FBF6EF|F7F3F0|FAF3EB|Color\.white\)|background\(Color\.white' "$APP_PATH"
echo

echo "== Scoped display residuals requiring follow-up range =="
run_scan "Weekly display residuals outside LG25 allowlist" 'foregroundStyle\(Color\.black|Color\.black\.opacity' \
  "$APP_PATH/Views/UI/Weekly/Sections/WeeklyOverviewSection.swift" \
  "$APP_PATH/Views/UI/Weekly/Sections/WeeklyTreemapComponents.swift"
run_scan "Chat control residuals outside LG26 allowlist" 'F4A867|E5D8CA' \
  "$APP_PATH/Views/UI/ChatView+State.swift"
echo

echo "== Deployment targets =="
run_scan "Deployment targets" 'MACOSX_DEPLOYMENT_TARGET = ' "$PROJECT_PBX"

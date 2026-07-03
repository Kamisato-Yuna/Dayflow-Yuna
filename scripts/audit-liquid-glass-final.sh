#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

echo "== Bundled video files =="
find Dayflow/Dayflow -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v'

echo
echo "== Bundled onboarding assets and removed main background references =="
rg -n 'DayflowAnimation|DayflowOnboarding|JournalOnboardingVideo|MainUIBackground' \
  Dayflow/Dayflow Dayflow/Dayflow.xcodeproj docs || true

echo
echo "== macOS 26 Liquid Glass API references =="
rg -n 'glassEffect|GlassEffect|GlassButtonStyle|GlassProminentButtonStyle|backgroundExtensionEffect|#available\(macOS 26|@available\(macOS 26' \
  Dayflow/Dayflow docs || true

echo
echo "== Background residuals to explain =="
rg -n 'Color\(red: 0\.98|FBF6EF|F7F3F0|FAF3EB|Color\.white\)|background\(Color\.white' \
  Dayflow/Dayflow || true

echo
echo "== Deployment targets =="
rg -n 'MACOSX_DEPLOYMENT_TARGET = ' Dayflow/Dayflow.xcodeproj/project.pbxproj

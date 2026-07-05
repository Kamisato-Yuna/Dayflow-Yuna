# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```bash
# Open project in Xcode
open Dayflow/Dayflow.xcodeproj

# If GRDB's SQLiteLib submodule fetch is flaky, rewrite it to the local mirror first.
# This expects SQLiteLib to sit next to this repository's parent directory.
REPO_PARENT=$(cd .. && pwd)
cat >/private/tmp/dayflow-gitconfig <<EOF
[url "file://${REPO_PARENT}/SQLiteLib"]
	insteadOf = https://github.com/swiftlyfalling/SQLiteLib.git
[protocol "file"]
	allow = always
EOF

# Build a local Debug app bundle from CLI
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Debug \
  -derivedDataPath build/local-derived \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build

# Launch the built app
open -n build/local-derived/Build/Products/Debug/Dayflow.app

# Confirm the launched build is still running
ps -ax | grep 'build/local-derived/Build/Products/Debug/Dayflow.app/Contents/MacOS/Dayflow' | grep -v grep

# Stop the locally built app (menu bar app, window close does not quit it)
pkill -f 'build/local-derived/Build/Products/Debug/Dayflow.app/Contents/MacOS/Dayflow'

# Run all tests via CLI
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived 2>&1 | tee xcodebuild.log

# Run a single test class
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived \
  -only-testing:DayflowTests/WeeklyDashboardBuilderTests

# Build Release
xcodebuild archive -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Release -archivePath build/Dayflow.xcarchive
```

Tests are in `Dayflow/DayflowTests/` (unit) and `Dayflow/DayflowUITests/` (UI). They import with `@testable import Dayflow`.
The project is a macOS app, not an iOS app, so use `platform=macOS` and validate runnable `.app` bundles under `build/local-derived/Build/Products/Debug/`.

### Build Artifact Hygiene

Use repository-local build output paths only. Keep Xcode derived data, visual QA builds, test builds, and release intermediates under `build/` or `Dayflow/DerivedData/`; these are ignored local artifact directories.

```bash
# Preview ignored build artifacts that can be removed
scripts/clean_build_artifacts.sh

# Clean derived data, test builds, visual QA builds, package caches, and old DMG output
scripts/clean_build_artifacts.sh --apply

# Clean build products but keep SwiftPM package caches
scripts/clean_build_artifacts.sh --keep-packages --apply

# Build/sign/package DMG using a clean release derived-data directory
./scripts/release_dmg.sh
```

`scripts/release_dmg.sh` defaults to `DERIVED_DATA=build/release-derived` and removes the previous release derived-data directory plus `Dayflow.dmg` before building. Set `CLEAN_RELEASE_BUILD=0` only when deliberately debugging an incremental release build.

Avoid adding user-specific absolute paths to this file. Prefer repository-relative paths, or compute absolute paths from `$(pwd)` only when a tool requires an absolute app path.

### Sandboxed xcodebuild

When running under a managed agent sandbox, `xcodebuild` can fail before the
real compile starts because Xcode/CoreSimulator tries to access user-level
services and logs outside the workspace. Typical symptoms include:

- `DVTFilePathFSEvents: Failed to start fs event stream.`
- `CoreSimulatorService connection became invalid.`
- `Error opening log file (~/Library/Logs/CoreSimulator/...): Operation not permitted`
- exit code `143` without Swift compile diagnostics.

Treat this as an environment/sandbox failure, not a product-code build failure.
Rerun the same `xcodebuild` command with elevated/approved permissions so Xcode
can reach CoreSimulator/log services. Only classify the build as a code failure
after the elevated run reaches the actual Swift/asset/link stages and reports a
compiler, linker, signing, or test error.

## Project Overview

Dayflow is a **macOS menu bar app** (macOS 14+) that captures periodic screen screenshots, sends them to an AI provider for analysis, and builds an automatic work journal timeline. It uses the **SwiftUI `App` lifecycle** with an `NSApplicationDelegate` (mixed SwiftUI + AppKit).

**SPM dependencies** (defined in the Xcode project): GRDB (SQLite), Sparkle (auto-update), Sentry (crash reporting), PostHog (analytics).

## Core Data Flow

```
ScreenRecorder (SCScreenshotManager, default 10s interval)
  → StorageManager (SQLite/GRDB: screenshots batched every ~15 min)
    → AnalysisManager (timer-driven, picks up unanalyzed batches)
      → LLMService → AI provider
          Step 1: transcribe screenshots → [Observation]
          Step 2: generate ActivityCards (sliding 45-min window)
        → StorageManager.replaceTimelineCardsInRange()
          → Timeline UI reads cards from SQLite
```

## AI Provider Architecture

Three active provider families (`Core/AI/LLMTypes.swift` → `LLMProviderType`):

| Provider | How it works | Keychain key |
|---|---|---|
| Gemini Direct | Native HTTP client, falls back to Gemma on transient errors | `"gemini"` |
| Ollama (local) | Connects to `localhost:11434` | — |
| ChatGPT/Claude CLI | Shells out to `codex` or `claude` CLI tools | — |

Each provider implements: `transcribeScreenshots`, `generateActivityCards` (batch pipeline), `generateText`/`generateTextStreaming`, and `generateChatStreaming` (dashboard chat). `LLMService` is the facade that routes to the selected provider and handles backup-provider failover.

Provider selection persists via `LLMProviderType` in UserDefaults. Legacy `dayflow` / `dayflowBackend` preferences are migrated to non-Dayflow providers before routing. A configurable backup provider enables automatic failover.

## Key Architectural Patterns

- **Singletons are the primary entry points**: `AppState.shared`, `StorageManager.shared`, `LLMService.shared`, `AnalysisManager.shared`.
- **GRDB is the single source of truth** for all persistent data. `StorageManager` owns the database queue; prefer its existing methods over raw SQL.
- **Screenshot-based, not video-based**: The app uses `SCScreenshotManager` for periodic still captures. Legacy video code (`VideoProcessingService`) remains but the primary path is screenshots.
- **Sliding window card generation**: When a new batch is analyzed, the LLM sees observations from a 45-minute lookback and can update existing timeline cards to maintain continuity across batch boundaries.
- **Menu bar app**: The app keeps running when the window is closed. `AppDelegate.allowTermination` defaults to `false` — only explicit flows (e.g., "Reset Onboarding" menu item) enable it. The status bar icon shows recording state via `StatusBarController`.
- **Storage location**: `~/Library/Application Support/Dayflow/` — contains the GRDB SQLite database and screenshot files.

## Key Directories

| Directory | Purpose |
|---|---|
| `App/` | `@main` entry point, `AppDelegate`, `AppState` (singleton for recording on/off state) |
| `Core/AI/` | All LLM providers, `LLMService` orchestration, `ChatService`, `DailyRecapGenerator`, streaming, prompt templates |
| `Core/Recording/` | `ScreenRecorder`, `StorageManager` (+ ~15 protocol extensions), `VideoProcessingService`, `JournalDayManager` |
| `Core/Analysis/` | `AnalysisManager` (timer-driven batch processing loop) |
| `Core/Weekly/` | `WeeklyDashboardBuilder` and sub-builders (heatmap, treemap, sankey, donut) |
| `Core/Security/` | `KeychainManager` — API keys stored in macOS Keychain |
| `Models/` | `TimelineCategory`, `ChatMessage`, `AnalysisModels` (Screenshot, Observation, ActivityCardData) |
| `Menu/` | `StatusMenuView` — menu bar dropdown |
| `System/` | `StatusBarController`, `AnalyticsService` (PostHog), `UpdaterManager` (Sparkle), `SentryHelper`, `LaunchAtLoginManager` |
| `Utilities/` | Helpers: `Color+Luminance`, `GeminiAPIHelper`, `TimelineClipboardFormatter`, `UserDefaultsMigrator` |
| `Views/Components/` | Reusable SwiftUI components (buttons, charts, pickers, goal flow cards) |
| `Views/Onboarding/` | Multi-step onboarding (LLM selection, API key input, CLI detection, category setup, screen recording permission) |
| `Views/UI/MainView/` | Main timeline UI (sidebar, activity cards, date nav, screenshot slideshow, week grid) |
| `Views/UI/` | Chat panel, daily standup, journal, weekly dashboard, settings tabs, timeline review |
| `Views/UI/Settings/` | Settings view models and tab content |
| `Views/UI/Weekly/` | Weekly dashboard section views |

## Selected UserDefaults Keys

- `selectedLLMProvider` / `llmProviderType` — active AI provider
- `didOnboard` — whether onboarding is complete
- `isRecording` — persisted recording state
- `screenshotIntervalSeconds` — capture interval (default 10)
- `chatCLIPreferredTool` — `"codex"` or `"claude"` for CLI-based provider

## Release

`scripts/release.sh` is the one-button release pipeline: bump version, build/sign/notarize DMG, sign Sparkle update, create GitHub Release, update `docs/appcast.xml`.

Requirements: Xcode + Developer ID cert, Sparkle CLI `sign_update`, `gh` CLI, notarization credentials.

# Liquid Glass UI Migration Inventory

Baseline date: 2026-07-03
Final cleanup update: 2026-07-03

This document started as the LG00 baseline for the Liquid Glass UI migration and
now also records the LG15 final cleanup state. It is the source of truth for
remaining visual-surface residuals, accessibility expectations, and video paths
that must be preserved.

## Scope Rules

- Do not change Swift UI code as part of LG00.
- macOS 15.1 is the minimum compatibility target for the migration.
- macOS 15 UI should use neutral, Codex desktop app-like translucent material:
  standard materials, light translucent fills, clear borders, and readable
  hierarchy.
- macOS 26+ UI may use Liquid Glass APIs, but only through a compatibility
  wrapper or an explicit `#available(macOS 26.0, *)` branch.
- Use Liquid Glass on functional layers: navigation, toolbar, popover, sheet,
  modal chrome, and floating controls.
- Keep content layers readable. Timeline cards, chart bodies, media content,
  text-heavy panels, and dashboards should prefer standard material, light fill,
  borders, and spacing over full-surface glass.
- Only remove bundled onboarding mp4 animations in the dedicated video-removal
  task. Do not remove or break runtime recording, playback, processing, or
  transcription video paths.

## LG15 Final Status

- Bundled onboarding mp4 files are no longer present under `Dayflow/Dayflow`.
- `MainUIBackground` is no longer referenced by production Swift or project
  resources.
- App and test deployment targets are set to macOS 15.1.
- macOS 26 Liquid Glass API use is centralized in:
  - `Dayflow/Dayflow/Views/Components/DayflowGlassSurface.swift`
  - `Dayflow/Dayflow/Views/UI/DayflowSurfaceStyles.swift`
- Functional surfaces use the shared material/glass wrappers. Content-heavy
  surfaces use semantic card/chart fills and borders instead of full-screen
  glass.
- Reduce Motion is respected by the live onboarding line animation and the
  interactive rating footer.
- Reduce Transparency and Increase Contrast are handled by the shared surface
  tokens and applied to the LG15-cleaned residual controls.

## Remaining Residuals And Reasons

These scan hits are intentionally kept:

| Residual | Location | Reason |
| --- | --- | --- |
| `Color.white` in `WhiteBGVideoPlayer` / video chrome | Runtime video playback views | This is runtime media playback backing or playback affordance contrast, not a bundled onboarding animation. Preserve the mp4 playback chain. |
| `Color.white` in `ScrubberView` | Runtime video scrubber filmstrip and playhead | The white strip/playhead is part of the media-control content layer. It is not a page background. |
| `Color.white` in screenshot slideshow / review media | Screenshot or video review content | These fills keep media thumbnails and selection affordances legible. |
| `Color.white` in previews | SwiftUI previews | Preview-only background scaffolding does not ship as an app surface. |
| `Color.white.opacity(...)` in semantic tokens | `DayflowSurfaceStyles.swift` | The token layer uses translucent neutral fills for macOS 15 material path and applies reduce-transparency fallbacks. |

Unresolved after LG15:

- Full GUI visual inspection on both macOS 15.7 and macOS 26+ still needs human
  runtime QA because this CLI pass can validate build/static state but cannot
  prove cross-version rendering in the current environment.

## macOS 15 And macOS 26 Visual Paths

- macOS 15.1 through macOS 15.x uses neutral AppKit/SwiftUI material, semantic
  fills, subtle borders, and reduced-transparency solid fallbacks.
- macOS 26+ uses the same semantic roles, with Liquid Glass enabled only for
  functional layers such as sidebar, floating controls, popovers, and modals via
  guarded wrapper code.
- Content layers such as timeline cards, charts, media, journal text, chat
  messages, and settings rows keep readable standard material/card fills rather
  than being glassed wholesale.

## Historical LG00 Baseline Findings

The LG00 validation scan originally found these major categories:

- Bundled onboarding videos, now removed:
  - `Dayflow/Dayflow/Videos/DayflowAnimation.mp4`
  - `Dayflow/Dayflow/Videos/DayflowOnboarding.mp4`
  - `Dayflow/Dayflow/Videos/JournalOnboardingVideo.mp4`
- Main window custom background, now removed:
  - `Dayflow/Dayflow/App/DayflowApp.swift` references `Image("MainUIBackground")`
    and a warm overlay `Color(red: 0.98, green: 0.96, blue: 0.93)`.
- Large-area warm backgrounds, now migrated or explained:
  - Weekly surfaces include `FBF6EF` and `F7F3F0` in `WeeklyView` and weekly
    section files.
  - Timeline, journal, chat, settings, onboarding, and modal surfaces contain
    many `Color.white` or warm white fills that need task-by-task review.
- Liquid Glass API baseline:
  - LG00 had no production Swift references. LG15 now finds guarded references
    only in the shared surface wrapper layer.

## Bundled Onboarding MP4 Inventory

These were the only bundled mp4 files found under `Dayflow/Dayflow/Videos/` at
LG00. They were migration candidates for LG02 and should stay absent after LG15.

| Asset | Current role | Current references | Later-task rule |
| --- | --- | --- | --- |
| `DayflowAnimation.mp4` | Launch video animation | Removed from production references | Keep absent; live line animation replaces this bundled asset. |
| `DayflowOnboarding.mp4` | Onboarding intro/prototype video name and analytics asset name | Removed from production references | Keep absent; semantic line-animation payloads replace the old asset names. |
| `JournalOnboardingVideo.mp4` | Journal onboarding video | Removed from production references | Keep absent; journal onboarding no longer depends on bundled mp4. |

## Runtime Video Paths To Preserve

These files are not bundled onboarding animations. Do not remove them when
cutting the three bundled mp4 assets.

| File | Runtime responsibility | Preserve because |
| --- | --- | --- |
| `Dayflow/Dayflow/Core/Recording/StorageManager+Chunks.swift` | Stores and fetches recording chunk metadata. | It is part of persisted runtime recording data. CodeGraph shows broad `StorageManager` dependents. |
| `Dayflow/Dayflow/Core/Recording/VideoProcessingService.swift` | Processes video files for analysis/transcription input. | CodeGraph shows analysis/transcription callers; this is not onboarding media. |
| `Dayflow/Dayflow/Views/UI/VideoPlayerModal.swift` | Runtime video playback modal and scrubber shell. | It uses dynamic file URLs and AV playback; preserve playback functionality while migrating modal chrome later. |
| `Dayflow/Dayflow/Views/UI/TimelineReviewMediaViews.swift` | Timeline review media presentation. | It is part of runtime review UI and media inspection. |
| `Dayflow/Dayflow/Views/UI/TimelineReviewPlaybackModels.swift` | Resolves runtime playback URLs. | It creates `AVPlayer` from resolved runtime URLs. |
| `Dayflow/Dayflow/Views/UI/WhiteBGVideoPlayer.swift` | AVPlayer hosting layer with white backing. | Treat white backing as a later visual-surface migration item, not a reason to delete video playback. |
| `Dayflow/Dayflow/Views/UI/VideoThumbnailView.swift` | Runtime video thumbnail/play affordance. | Migrate chrome only in later UI tasks. |
| `Dayflow/Dayflow/Views/UI/ScrubberView.swift` | Runtime scrubber timeline. | Preserve playback and review interaction. |

## UI Surface Inventory

Use these buckets to decide task scope before editing. Files can appear in more
than one bucket when a view owns both shell and content.

| Surface | Primary files | Migration notes |
| --- | --- | --- |
| Launch | `Dayflow/Dayflow/App/DayflowApp.swift`, `Dayflow/Dayflow/Views/Onboarding/VideoLaunchView.swift` | Remove custom launch video in LG02; remove `MainUIBackground` in LG03. |
| Onboarding | `Dayflow/Dayflow/Views/Onboarding/OnboardingFlow.swift`, `LLMProviderSetupView.swift`, `OnboardingLLMSelectionView.swift`, `OnboardingCategoryStepView.swift`, `ScreenRecordingPermissionView.swift`, `SetupSidebarView.swift`, `ChatCLIDetectionViews.swift`, prototype onboarding files | Use material shell and clear step hierarchy. Avoid glassing text-heavy cards. |
| Timeline shell | `Dayflow/Dayflow/Views/UI/MainView/MainView.swift`, `Layout.swift`, `Layout+Panels.swift`, `Layout+TimelineHeader.swift`, `SidebarView.swift`, `TabFilterBar.swift`, `WeekTimelineGridView.swift` | Navigation/header/floating controls are glass candidates; timeline content stays readable. |
| Timeline content and media | `ActivityCard.swift`, `ScreenshotSlideshow.swift`, `CanvasTimelineDataView.swift`, `TimelineReviewOverlay.swift`, `TimelineReviewChrome.swift`, `TimelineFeedbackModal.swift`, `TimelineReviewMediaViews.swift`, `VideoPlayerModal.swift` | Preserve runtime screenshot/video review. Modal chrome can migrate; media canvas should not be over-glassed. |
| Daily | `Dayflow/Dayflow/Views/UI/DailyView.swift`, `DailyView+Standup.swift`, `DailyView+Workflow.swift`, `DailyWorkflowGrid.swift`, `DailyAccessLockedViews.swift`, `DailyStandupComponents.swift`, `Dayflow/Dayflow/Views/Components/DayGoalFlowView.swift` | Cards and grids need content surfaces; floating controls can use material/glass. |
| Weekly shell | `Dayflow/Dayflow/Views/UI/Weekly/WeeklyView.swift`, `WeeklyAccessLockedView.swift`, weekly section files | Warm full-page backgrounds are known residuals. Chart canvases should remain stable content surfaces. |
| Journal | `Dayflow/Dayflow/Views/UI/JournalView.swift`, `JournalHeroView.swift`, `JournalDayView.swift`, `JournalWeeklyView.swift`, `JournalReminders.swift` | Hero and navigation can migrate; journal entries and reminders need readable content fill. |
| Chat | `Dayflow/Dayflow/Views/UI/ChatView.swift`, `ChatView+Content.swift`, `ChatPanelView.swift`, `ChatMessageViews.swift`, `ChatWelcomeComponents.swift`, `ChatWorkStatusViews.swift`, `Dayflow/Dayflow/Views/Components/ToolCallBubble.swift` | Composer/status/tool chips are glass candidates; message bodies should prioritize legibility. |
| Settings | `Dayflow/Dayflow/Views/UI/SettingsView.swift`, `Settings/SettingsStorageTabView.swift`, `SettingsRecordingPrivacyTabView.swift`, `SettingsProvidersTabView.swift`, `SettingsDataTabView.swift`, `SettingsOtherTabView.swift`, `SettingsComponents.swift` | Keep dense settings scannable. Use subtle panels rather than decorative glass everywhere. |
| Popover | `Dayflow/Dayflow/Views/UI/MainView/TimelineCalendarPopover.swift`, `Dayflow/Dayflow/Views/Components/CategoryPickerView.swift`, `CategoryPickerOverlay.swift`, `DayCategorySelectionEditor.swift` | Popovers and picker shells are functional layers and should use material/glass where available. |
| Modal and sheet | `BugReportView.swift`, `TimelineFeedbackModal.swift`, `WhatsNewView.swift`, `VideoPlayerModal.swift` | Migrate modal chrome and controls while preserving content contrast and runtime video playback. |

## Screenshot Acceptance Checklist

Capture these states for visual QA after each later migration task. Compare
macOS 15.1 and macOS 26+ separately when both runtimes are available.

- Launch: app startup without `MainUIBackground` artifacts; no missing video
  placeholder after bundled mp4 removal.
- Onboarding: intro, provider selection, CLI detection, API key, category,
  screen recording permission, completion.
- Timeline: sidebar, timeline header, tab filter, activity cards, screenshot
  slideshow, failed/empty/loading states.
- Daily: locked state, standup, workflow grid, goal flow, permission/provider
  onboarding panels.
- Weekly: locked state, overview, Sankey, application interactions, heatmap,
  treemap, workflow, suggestions, context charts.
- Journal: hero, day view, week view, reminders, onboarding entry/video
  replacement state.
- Chat: welcome state, message list, streaming status, tool calls, composer,
  charts.
- Settings: storage, recording/privacy, providers, data, other tabs.
- Popover: calendar popover, category picker, category overlay/editor.
- Modal: feedback modal, bug report, What's New, video playback modal.
- Accessibility: Reduce Transparency, Increase Contrast, Reduce Motion, keyboard
  focus, VoiceOver labels for icon-only controls.

## Reusable Scan Commands

Run from the repository root.

LG15 final audit wrapper:

```bash
bash scripts/audit-liquid-glass-final.sh
```

```bash
rg -n 'DayflowAnimation|DayflowOnboarding|JournalOnboardingVideo|MainUIBackground|Color\(red: 0\.98|Color\.white|FBF6EF|F7F3F0' Dayflow/Dayflow docs
```

```bash
rg -n 'DayflowAnimation|DayflowOnboarding|JournalOnboardingVideo|Bundle\.main\.url\(forResource:.*mp4|AVPlayerItem\(url:' Dayflow/Dayflow Dayflow/Dayflow.xcodeproj docs
```

```bash
rg -n 'glassEffect|GlassEffect|GlassButtonStyle|GlassProminentButtonStyle|backgroundExtensionEffect|#available\(macOS 26|@available\(macOS 26' Dayflow/Dayflow docs
```

```bash
rg -n 'Color\(red: 0\.98|FBF6EF|F7F3F0|FAF3EB|FFF2DB|background\(Color\.white|\.background\(Color\.white' Dayflow/Dayflow
```

```bash
git diff --check
```

## Later Task Decision Guide

- If a task touches bundled onboarding video references, confirm that all
  changes are limited to launch/onboarding/journal onboarding paths and do not
  edit runtime review or processing paths.
- If a task introduces macOS 26 APIs, keep them inside the shared surface
  wrapper or inside explicit availability branches.
- If a task changes a full-page background, verify content surfaces still have
  enough contrast on macOS 15.1 and do not become full-screen glass.
- If a task changes a popover, sheet, toolbar, or floating control, prefer
  system materials and controls first; add custom Liquid Glass only where the
  standard structure does not cover the design.
- If the residual scan still reports files outside the current task allowlist,
  leave them for their numbered task instead of broadening scope.

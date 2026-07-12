# Repository Agent Instructions

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tools** (when available): `codegraph_explore` answers most code questions in one call - the relevant symbols' verbatim source plus the call paths between them. `codegraph_node` returns one symbol's source + callers, or reads a whole file with line numbers. If the tools are listed but deferred, load them by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` and `codegraph node <symbol-or-file>` print the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely - indexing is the user's decision.
<!-- CODEGRAPH_END -->

## Dayflow Visual QA

LG28 / Computer Use visual acceptance is a Codex-only workflow. Computer Use is a Codex desktop capability and may not exist in Claude, CI, terminal-only agents, or non-Codex environments. If Computer Use is unavailable, do not pretend it was used; record the limitation and use manual screenshots or `screencapture` as a fallback.

When validating Dayflow's Liquid Glass UI visually, avoid accidentally opening the installed production app or an old `derivedData` product:

1. Build the current source into a task-specific derived data directory, for example `build/<task>-visual-derived`.
2. Confirm the `.app` exists at an absolute path under the current repository, not `/Applications` and not an older `build/local-derived` path unless the task explicitly chose that path.
3. Before launching, check for existing Dayflow processes. If a running Dayflow process points at the production app or a stale build path, stop and report it before judging screenshots.
4. Launch with an absolute path, for example:
   `open -n -F "$(pwd)/build/<task>-visual-derived/Build/Products/Debug/Dayflow.app"`
5. Verify the running executable path with `pgrep -afil Dayflow` or an equivalent process-path check. The PID must point at the same absolute `.app` path being reviewed.
6. Verify `Contents/Info.plist` for `LSMinimumSystemVersion`, `CFBundleShortVersionString`, and `CFBundleVersion`.
7. In Codex desktop, call Computer Use `get_app_state` with the full `.app` path, not just `Dayflow` or the bundle id. The returned app path and PID must match the process-path check.
8. Navigate the actual app window with Computer Use and review at least Timeline, Daily, Weekly, Chat, Feedback, Settings, and Settings sub-tabs touched by the task.
9. If a permission overlay or toast blocks content, capture the blocked state first, then close it and continue the page review.
10. The final report must include the app path, PID, source commit or branch, Info.plist version fields, pages reviewed, and whether Computer Use was used or unavailable.

For Liquid Glass migration work, visual QA findings must distinguish product defects from environment/tooling issues. A sandboxed Xcode or process-list failure is not a UI regression; record it separately and rerun with the approved repository validation path when required.

## Build Artifact Hygiene

Keep generated Xcode and packaging output under `build/` or `Dayflow/DerivedData/`; both are ignored local artifact locations. Before creating a new test build or packaging a DMG, remove stale products so screenshots, process checks, and release files refer to the current source.

- Preview removable local artifacts with `scripts/clean_build_artifacts.sh`.
- Delete ignored build artifacts with `scripts/clean_build_artifacts.sh --apply`.
- Preserve SwiftPM package caches while cleaning derived data with `scripts/clean_build_artifacts.sh --keep-packages --apply`.
- The DMG pipeline uses `build/release-derived` by default and cleans that release derived-data directory plus the previous `Dayflow.dmg` before each run. Set `CLEAN_RELEASE_BUILD=0` only when deliberately debugging an incremental release build.
- Avoid hard-coded user-specific absolute paths in these instructions. Use paths relative to the repository root, or compute absolute paths from `$(pwd)` when a tool requires one.

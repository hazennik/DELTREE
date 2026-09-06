# Changelog

All notable changes to DELTREE will be documented here.

The format follows Keep a Changelog-style sections, and versions should use semantic versioning once releases begin.

## Unreleased

### Added

- Added `Check for Updates...` to the menu-bar mini menu for Sparkle-enabled builds.
- Added automatic update preferences and an explicit `Install Update and Relaunch` action to Settings and the menu-bar mini menu.
- Added launch-at-login support through macOS `SMAppService`.
- Added a `Review Items` hover submenu that lists every non-ignored item needing review and opens the selected item in the dashboard.
- Added expandable cleanup-history details for completed, skipped, and failed paths.
- Added macOS 14 Apple Silicon and macOS 15 Intel compatibility lanes to CI.

### Fixed

- Prevented repeated Documents access prompts after `~/Documents/Codex` access is denied; users can explicitly retry from Settings.
- Prevented duplicate cleanup submissions from canceling an in-progress cleanup and reporting cancellation as per-item failures.
- Made `~/Documents/Codex` opt-in so first launch and background scans do not request Documents access.
- Excluded incomplete or unreadable scans from cleanup and revalidated filesystem identity, complete size, and open files immediately before every Trash action.
- Refreshed `simctl` device state immediately before every simulator mutation.
- Replaced free-text custom-root and exclusion editing with validated macOS file pickers.
- Restored one theme-independent menu-bar status icon while preserving theme-specific application icons.
- Fixed Settings unit labels so values such as `Minutes` do not wrap inside numeric fields.

### Changed

- Made Modern the default visual mode; Classic remains available as the retro theme.
- Expanded UI smoke tests to render and validate all documented app surfaces.

## [1.0.0-rc.2] - 2026-08-31

### Fixed

- Updated the downloadable app package to use the modern blue folder app icon as DELTREE's default app icon.

## [1.0.0-rc.1] - 2026-08-30

### Added

- Public release readiness automation and documentation refinements.
- Protected GitHub Pages prerelease update feed and validated appcast staging workflow.
- Bundled DELTREE, Sparkle, and bundled-component license notices in distributed apps.
- Initial LSUIElement menu-bar app shell.
- Abstract icon-only menu-bar state indicator.
- Storage scanners for Codex and Xcode developer paths.
- Simulator metadata enrichment through `simctl`.
- Codex/Xcode attribution and recent-growth tracking.
- Conservative safety classification and cleanup preflight.
- Trash-based cleanup execution and approved simulator commands.
- SwiftData scan, delta, override, attribution, and cleanup history.
- Dashboard, filters, details, rules, settings, and cleanup history.
- Bounded `deltree` CLI dry-run helper.
- Packaging and release scaffolding.
- Agent guidance for cleanup safety, privacy, testing, and release work.
- View-facing dashboard tests for menu labels, filtering, summaries, and selection.
- A stable Apple Development build target for repeated macOS permission testing.

### Changed

- Simulator cleanup now uses only explicit `simctl` actions and accurately warns when simulator data removal is irreversible.
- Persistence-store fallback now presents a visible warning when history will not be saved.
- Sparkle is pinned to exact version 2.9.6 instead of accepting any future 2.x release during dependency resolution.
- Release documentation now distinguishes first-candidate install testing from the two-candidate Sparkle update test required before public GA.
- The README now leads with Codex attribution, explains DELTREE's scope among developer cleaners, and routes detailed process documentation through the documentation index.

### Fixed

- Prevented available CoreSimulator device directories from entering direct Trash cleanup.
- Prevented the detail pane from showing an item hidden by the active dashboard filters.

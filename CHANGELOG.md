# Changelog

All notable changes to DELTREE will be documented here.

The format follows Keep a Changelog-style sections, and versions should use semantic versioning once releases begin.

## Unreleased

### Added

- Public release readiness automation and documentation refinements.
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

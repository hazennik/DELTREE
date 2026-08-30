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

### Changed

- Simulator cleanup now uses only explicit `simctl` actions and accurately warns when simulator data removal is irreversible.
- Persistence-store fallback now presents a visible warning when history will not be saved.

### Fixed

- Prevented available CoreSimulator device directories from entering direct Trash cleanup.

# Agent Guide

This file applies to the entire repository. DELTREE is a pre-release macOS utility that inspects and cleans developer storage, so data-safety changes require stronger evidence than ordinary UI changes.

## Start Here

- Read `README.md`, `docs/ARCHITECTURE.md`, and `docs/SAFETY.md` before changing behavior.
- Use `rg` and `rg --files` for repository search.
- Preserve unrelated local changes and never commit personal signing identities, Team IDs, credentials, private paths, or real Codex transcripts.

## Safety Invariants

- Keep scans bounded to known developer roots unless the user explicitly adds a custom root.
- Regular files and folders move to Trash; do not add permanent regular-file deletion.
- Simulator cleanup must use the approved `simctl delete` or `simctl erase` paths and must identify the action as irreversible.
- Never clean booted, active, pinned, ignored, protected-domain, unreadable, or revalidation-failed items.
- Keep cleanup opt-in and preserve the final executor revalidation immediately before mutation.
- Keep scan data, paths, attribution, and cleanup history local. Do not add analytics, telemetry, crash uploads, or network reporting without an explicit privacy review.

## Code And Tests

- The app uses Swift 6 strict concurrency, SwiftUI, Observation, and SwiftData on macOS 14 or newer.
- Put view-facing state and decisions in testable models or view models; do not unit-test SwiftUI view construction directly.
- Use Swift Testing for unit and integration tests. XCTest is reserved for UI automation.
- Add focused regression tests for scanner, attribution, safety, cleanup, filtering, selection, or persistence behavior that changes.
- Keep release signing, notarization, and Sparkle credentials outside the repository.

## Validation

Run the narrowest relevant checks while iterating, then run the full gate before requesting review:

```sh
make check
make ui-test
```

`make ui-test` is required when launch or menu-bar behavior changes. A signed, stable-identity development build for repeated macOS permission testing is available through `make signed-dev-build`; see `docs/DEVELOPMENT.md`.

## Pull Requests

- Keep changes scoped and explain data-safety impact.
- Update user, safety, privacy, or release documentation when behavior changes.
- Follow `.github/PULL_REQUEST_TEMPLATE.md` and keep every required status check green.
- Do not weaken protected-branch, signed-commit, dependency-pin, release-asset, or secret-scanning controls.

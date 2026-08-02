# DELTREE

DELTREE is a local-only macOS menu-bar utility for understanding and safely managing the disk space created by Codex-driven iOS and macOS development.

It scans bounded Codex and Xcode storage locations, explains what it found, labels cleanup risk, and only performs cleanup after explicit confirmation.

> Status: private development repository. The app is functional, but the release process still needs real Developer ID, notarization, and Sparkle credentials.

## What It Does

- Shows Codex/Xcode storage impact from a quiet menu-bar icon.
- Scans CoreSimulator devices, XCTest devices, DerivedData, result bundles, archives, DeviceSupport, simulator runtimes/images, SwiftPM caches, `~/.codex`, and Codex workspaces.
- Enriches simulator rows with `simctl` metadata.
- Correlates filesystem changes with Codex, Xcode, `xcodebuild`, `simctl`, Simulator, and CoreSimulatorService activity.
- Labels items as `Safe to Remove`, `Probably Safe`, `Review First`, `Do Not Remove`, or `Unknown`.
- Moves approved files to Trash instead of hard-deleting them.
- Uses approved `simctl delete` and `simctl erase` commands for simulator-specific actions.
- Persists scan history, recent growth, manual overrides, and cleanup records with SwiftData.

## Safety Defaults

DELTREE is intentionally conservative.

- No full-disk crawl by default.
- No silent cleanup.
- No permanent file deletion in v1.
- Booted or active simulators are never cleaned.
- Archives, dSYMs, runtimes, DeviceSupport, and simulator images are excluded from one-click cleanup.
- Every cleanup plan is revalidated before execution.

Read the full policy in [docs/SAFETY.md](docs/SAFETY.md).

## Menu Bar States

The menu-bar item is icon-only:

- Outline icon: idle.
- Filled icon: scanning.
- Green dot: reclaimable storage found.
- Orange dot: warning, low disk, or unreadable paths.

Totals and explanations live in the dropdown and dashboard so the menu bar stays quiet.

## Build

Requirements:

- macOS with Xcode installed.
- Xcode 17 or newer for the current project settings.
- Swift 6-era toolchain from Xcode.

Open the project:

```sh
open DELTREE.xcodeproj
```

Run tests:

```sh
xcodebuild test -scheme DELTREE -project DELTREE.xcodeproj -destination 'platform=macOS'
```

## CLI Helper

The bundled helper performs a bounded dry-run inventory and never deletes files:

```sh
Tools/deltree --dry-run
Tools/deltree --dry-run --json
```

Install it locally:

```sh
Scripts/install-cli.sh
```

## Distribution

DELTREE is intended for Developer ID distribution outside the Mac App Store because it needs to inspect developer folders and move approved items to Trash.

Packaging notes live in [Packaging/README.md](Packaging/README.md) and release steps live in [docs/RELEASING.md](docs/RELEASING.md).

## Documentation

- [User Guide](docs/USER_GUIDE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Development](docs/DEVELOPMENT.md)
- [Safety Policy](docs/SAFETY.md)
- [CLI](docs/CLI.md)
- [Release Process](docs/RELEASING.md)
- [Third-Party Notices](THIRD_PARTY_NOTICES.md)

## Privacy

DELTREE is local-only. It reads known developer paths, local Codex metadata when present, and local process state for attribution. It does not upload scan results, cleanup history, paths, account data, or project metadata.

## License

MIT. See [LICENSE](LICENSE).


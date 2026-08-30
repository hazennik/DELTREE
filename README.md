# DELTREE

[![CI](https://github.com/hazennik/DELTREE/actions/workflows/ci.yml/badge.svg)](https://github.com/hazennik/DELTREE/actions/workflows/ci.yml)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-0f766e)](https://www.apple.com/macos/)
[![Swift 6](https://img.shields.io/badge/Swift-6-f05138)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

DELTREE is a privacy-first macOS menu-bar utility for understanding and safely managing the disk space created by Codex-driven iOS and macOS development.

Unlike general developer-cache cleaners, it correlates bounded filesystem changes with local Codex tasks and Xcode activity. It explains what it found, labels cleanup risk, and revalidates every cleanup action immediately before execution.

```text
C:\> DELTREE
SCAN CODEX + XCODE STORAGE
TRASH ONLY. LOCAL DATA. NO TELEMETRY.
```

> Status: pre-release. Signed and notarized `v1.0.0-rc.1` is available for clean-machine testing. It is not public GA: clean-machine QA is still pending, and the complete Sparkle update path must be proven from RC.1 to a second signed candidate.

## Install

Download the signed and Apple-notarized RC.1 test candidate from [GitHub Releases](https://github.com/hazennik/DELTREE/releases/tag/v1.0.0-rc.1):

```sh
release_tag="v1.0.0-rc.1"
curl -fL -o DELTREE.zip "https://github.com/hazennik/DELTREE/releases/download/$release_tag/DELTREE.zip"
ditto -x -k DELTREE.zip .
open DELTREE.app
```

RC.1 is for release-candidate testing. To build from source instead:

```sh
git clone https://github.com/hazennik/DELTREE.git
cd DELTREE
make build
open build/DerivedData/Build/Products/Debug/DELTREE.app
```

`make build` creates an unsigned, CI-equivalent build. For repeated local use where macOS file-access grants must survive rebuilds, use a stable Apple Development identity:

```sh
DELTREE_DEVELOPMENT_SIGNING_IDENTITY="APPLE_DEVELOPMENT_CERTIFICATE_SHA1" make signed-dev-build
open build/DerivedData/Build/Products/Debug/DELTREE.app
```

Keep the same certificate and bundle identifier between builds. No personal Team ID, certificate fingerprint, or signing identity belongs in the repository. See [Permissions & Troubleshooting](docs/PERMISSIONS.md) for details.

Homebrew Cask support is planned after signed and notarized GitHub Releases are proven. No DELTREE cask is published yet.

## Build

Requirements:

- macOS 14 or newer.
- Xcode 17 or newer for the Swift 6 strict-concurrency project settings.
- Swift 6-era toolchain from Xcode.

Common commands:

```sh
make build
make test
make swift-test
make analyze
make cli-dry-run
```

`make test` runs the unit test bundle. `make ui-test` performs a deterministic signed menu-bar launch smoke test. The legacy Xcode UI automation runner remains available as `make xcode-ui-test` for local investigation.

Formatting and linting use SwiftFormat and SwiftLint:

```sh
brew install swiftformat swiftlint
make lint
make format
```

The SwiftPM package exposes the app's core models and services as `DELTREECore`, so contributors can run focused tests without opening Xcode:

```sh
swift test
```

Release dry-runs validate the packaging, notarization, and appcast command paths without signing credentials:

```sh
make package-check
make appcast-check
make spark-sign-check
```

## Privacy

DELTREE processes storage data locally. It reads known developer paths, local Codex metadata when present, and local process state for attribution. It does not upload scan results, cleanup history, paths, account data, or project metadata. Direct Developer ID builds may contact GitHub Releases over HTTPS through Sparkle to check for updates; update checks do not include DELTREE scan data.

Read the full policy in [PRIVACY.md](PRIVACY.md).

## Safety

DELTREE is intentionally conservative.

- No full-disk crawl by default.
- No silent cleanup.
- Regular files and folders are moved to Trash; explicit simulator delete/erase actions permanently remove simulator data.
- Booted or active simulators are never cleaned.
- Archives, dSYMs, runtimes, DeviceSupport, and simulator images are excluded from one-click cleanup.
- Every cleanup plan is revalidated before execution.

Read the full policy in [docs/SAFETY.md](docs/SAFETY.md).

## Why DELTREE

Several tools can remove Xcode or general developer caches. DELTREE focuses on explaining storage created during Codex-driven Apple-platform work:

- Local Codex task and process attribution, with confidence shown instead of treated as certainty.
- Bounded developer-storage scanning rather than a default full-disk crawl.
- Protected archives, runtimes, images, and DeviceSupport instead of broad one-click deletion.
- A reviewed cleanup plan plus final execution-time revalidation, with regular files moved to Trash.

## Screenshots

Modern is the primary public screenshot set because it best matches repeated day-to-day macOS use.

![Modern dashboard](docs/assets/screenshots/modern-dashboard.png)

![Modern menu-bar dropdown](docs/assets/screenshots/modern-menu-bar-dropdown.png)

![Modern cleanup preflight](docs/assets/screenshots/modern-cleanup-preflight.png)

Classic keeps the retro command-prompt identity available as a smaller secondary set.

<p>
  <img src="docs/assets/screenshots/classic-dashboard.png" alt="Classic dashboard" width="49%">
  <img src="docs/assets/screenshots/classic-menu-bar-dropdown.png" alt="Classic menu-bar dropdown" width="32%">
</p>

## What It Does

- Correlates filesystem changes with local Codex tasks and Codex, Xcode, `xcodebuild`, `simctl`, Simulator, and CoreSimulatorService activity.
- Shows Codex/Xcode storage impact from a quiet menu-bar icon.
- Uses DELTREE Classic by default: terminal-style panels, monospaced scan output, block storage meters, and explicit `[SAFE]` / `[REVIEW]` / `[KEEP]` labels.
- Keeps the previous macOS-native visual system available as `Modern` from Settings.
- Scans CoreSimulator devices, XCTest devices, DerivedData, result bundles, archives, DeviceSupport, simulator runtimes/images, SwiftPM caches, `~/.codex`, and Codex workspaces.
- Enriches simulator rows with `simctl` metadata.
- Labels items as `Safe to Remove`, `Probably Safe`, `Review First`, `Do Not Remove`, or `Unknown`.
- Moves approved files to Trash instead of hard-deleting them.
- Uses explicit `simctl delete` and `simctl erase` commands for simulator-specific actions and identifies them as irreversible in cleanup preflight.
- Persists scan history, recent growth, manual overrides, and cleanup records with SwiftData.

## Menu Bar States

The menu-bar item is icon-only:

- Outline or pixel icon: idle.
- Filled icon: scanning.
- Green/cyan dot: reclaimable storage found.
- Orange/amber dot: warning, low disk, or unreadable paths.

Totals and explanations live in the dropdown and dashboard so the menu bar stays quiet.

## CLI Helper

The bundled helper performs a bounded dry-run inventory and never deletes files:

```sh
Tools/deltree --dry-run
Tools/deltree --dry-run --json
```

Human output uses the Classic terminal dashboard style. JSON output remains stable for scripts.

Install it locally:

```sh
Scripts/install-cli.sh
```

## Distribution

DELTREE is intended for Developer ID distribution outside the Mac App Store because it needs to inspect developer folders and move approved items to Trash.

Packaging notes live in [Packaging/README.md](Packaging/README.md), release steps live in [docs/RELEASING.md](docs/RELEASING.md), and local signing setup lives in [docs/LOCAL_RELEASE.md](docs/LOCAL_RELEASE.md). Public distribution uses local Developer ID signing, Apple notarization, Sparkle appcast signing, and GitHub Release asset hosting.

## Documentation

- [User Guide](docs/USER_GUIDE.md)
- [Safety Policy](docs/SAFETY.md)
- [Privacy](PRIVACY.md)
- [Development](docs/DEVELOPMENT.md)
- [Release Readiness](docs/PUBLIC_RELEASE_CHECKLIST.md)
- [Complete Documentation Index](docs/INDEX.md)

## License

MIT. See [LICENSE](LICENSE).

# User Guide

DELTREE helps iOS and macOS developers see what disk space Codex and Xcode are creating during build, test, and simulator workflows.

## First Launch

1. Launch `DELTREE.app`.
2. Look for the DELTREE icon in the macOS menu bar.
3. Open the menu and choose `Scan Now`.
4. Open the dashboard to inspect detailed results.

The app does not open a Dock icon or a window by default.

## What DELTREE Scans

DELTREE scans bounded developer paths by default:

- `~/.codex`
- `~/Documents/Codex`
- `~/Library/Developer/CoreSimulator/Devices`
- `~/Library/Developer/XCTestDevices`
- `~/Library/Developer/Xcode/DerivedData`
- `~/Library/Developer/Xcode/Products`
- `~/Library/Developer/Xcode/Archives`
- `~/Library/Developer/Xcode/iOS DeviceSupport`
- `~/Library/Developer/CoreSimulator/Caches`
- `~/Library/Developer/CoreSimulator/Profiles/Runtimes`
- `/Library/Developer/CoreSimulator/Profiles/Runtimes`
- `/Library/Developer/CoreSimulator/Images`
- SwiftPM cache locations

Unreadable or missing paths are reported instead of hidden.

## Understanding Safety Labels

- `Safe to Remove`: generated or stale data DELTREE can include in safe cleanup.
- `Probably Safe`: usually rebuildable, but review before removing.
- `Review First`: may be important or shared across projects.
- `Do Not Remove`: active, pinned, ignored, runtime, image, or protected data.
- `Unknown`: not enough evidence to recommend cleanup.

## Cleanup

DELTREE always shows a cleanup preflight before action. The preflight lists:

- exact items
- total reclaimable bytes
- blocked items
- risks
- action explanations

File and folder cleanup moves items to Trash. Simulator cleanup uses explicit `simctl` actions when appropriate.

## Manual Overrides

Use the detail inspector to:

- mark an item as user-owned
- ignore an item
- pin an item
- reset attribution
- reveal the item in Finder
- copy its path

Overrides persist across scans.


# User Guide

DELTREE helps iOS and macOS developers see what disk space Codex and Xcode are creating during build, test, and simulator workflows.

## First Launch

1. Launch `DELTREE.app`.
2. Look for the DELTREE icon in the macOS menu bar.
3. Open the menu and choose `Scan Now`.
4. Open the dashboard to inspect detailed results.

The app does not open a Dock icon or a window by default.

## Appearance

DELTREE Classic is the default visual mode. It uses terminal-style panels, monospaced metrics, block storage meters, and explicit safety tags such as `[SAFE]`, `[REVIEW]`, `[KEEP]`, and `[UNKNOWN]`.

To restore the previous macOS-native look:

1. Open the menu-bar item.
2. Choose `Settings...`.
3. Set `Visual Mode` to `Modern`.

Changing visual mode only changes presentation. It does not start a scan, alter safety classifications, or change cleanup behavior.

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

File and folder cleanup moves items to Trash. Simulator cleanup uses explicit `simctl` actions when appropriate. `simctl delete` and `simctl erase` permanently remove the affected simulator data and cannot be recovered from Trash; the preflight identifies these actions before confirmation.

## Manual Overrides

Use the detail inspector to:

- mark an item as user-owned
- ignore an item
- pin an item
- reset attribution
- reveal the item in Finder
- copy its path

Overrides persist across scans.

## Updates

Direct Developer ID installs use `Check for Updates...` from the app menu when Sparkle is configured for the build.

Homebrew installs should update with:

```sh
brew upgrade --cask deltree
```

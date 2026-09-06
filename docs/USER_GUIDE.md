# User Guide

DELTREE helps iOS and macOS developers see what disk space Codex and Xcode are creating during build, test, and simulator workflows.

## First Launch

1. Launch `DELTREE.app`.
2. Look for the DELTREE icon in the macOS menu bar.
3. Open the menu and choose `Scan Now`.
4. Open the dashboard to inspect detailed results.

The app does not open a Dock icon or a window by default.

## Appearance

DELTREE Modern is the default visual mode. It uses macOS-native controls and a compact interface intended for repeated day-to-day use.

To use the retro terminal-style interface:

1. Open the menu-bar item.
2. Choose `Settings...`.
3. Set `Visual Mode` to `Classic`.

Classic uses monospaced metrics, block storage meters, and explicit safety tags such as `[SAFE]`, `[REVIEW]`, `[KEEP]`, and `[UNKNOWN]`.

Changing visual mode only changes presentation. It does not start a scan, alter safety classifications, or change cleanup behavior.

## What DELTREE Scans

DELTREE scans bounded developer paths by default:

- `~/.codex`
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

`~/Documents/Codex` is off by default. Enable it in Settings, then run a user-initiated scan if you want DELTREE to inspect that location. macOS may ask for Documents access once. Custom scan roots and exclusions are added with the system file picker; DELTREE rejects relative, overlapping, home-level, and broad system roots.

## Understanding Safety Labels

- `Safe to Remove`: generated or stale data DELTREE can include in safe cleanup.
- `Probably Safe`: usually rebuildable, but review before removing.
- `Review First`: may be important or shared across projects.
- `Do Not Remove`: active, pinned, ignored, runtime, image, or protected data.
- `Unknown`: not enough evidence to recommend cleanup.

The menu-bar mini menu shows a `Review Items` submenu under Cleanup Readiness when non-ignored items are classified as `Probably Safe` or `Review First`. Hover over it to see the complete size-sorted list. Selecting an item opens the dashboard with that item ready for inspection; it does not clean or reclassify the item.

## Cleanup

DELTREE always shows a cleanup preflight before action. The preflight lists:

- exact items
- total reclaimable bytes
- blocked items
- risks
- action explanations

File and folder cleanup moves items to Trash. Simulator cleanup uses explicit `simctl` actions when appropriate. `simctl delete` and `simctl erase` permanently remove the affected simulator data and cannot be recovered from Trash; the preflight identifies these actions before confirmation.

Immediately before a Trash action, DELTREE confirms that the path is still the same filesystem object, re-scans its size completely, and checks for open files. Items that changed or cannot be fully revalidated are skipped. Expand a record in Cleanup History to see completed, skipped, and failed paths with their failure reasons.

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

Direct Developer ID installs can configure automatic checks and downloads in Settings. Use `Check for Updates...` from the menu-bar mini menu or Settings. After Sparkle downloads and validates an update, use `Install Update and Relaunch` from either location.

Settings also provides `Launch DELTREE at login`. macOS may require approval in System Settings after it is enabled.

Homebrew installs should update with:

```sh
brew upgrade --cask deltree
```

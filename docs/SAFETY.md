# Safety Policy

DELTREE exists to explain and safely reclaim developer storage. It should never surprise the user.

## Hard Rules

- Never clean booted or active simulators.
- Never permanently delete files in v1.
- Never silently clean anything.
- Always revalidate cleanup plans before execution.
- Check non-simulator cleanup candidates with `lsof` before labeling them safe.
- Always use Trash for file and folder cleanup.
- Only use `simctl delete` or `simctl erase` for explicit simulator actions.
- Never include archives, dSYMs, runtimes, DeviceSupport, or simulator images in one-click safe cleanup.

## One-Click Safe Cleanup

Only `Safe to Remove` items with safe actions are eligible.

Examples:

- stale Codex-attributed XCTest devices
- unavailable simulator devices
- old `.xcresult` bundles
- stale Codex temporary/work folders
- stale CoreSimulator caches

## Review-First Data

These are usually not included in safe cleanup:

- DerivedData without strong Codex attribution
- SwiftPM caches
- recent result bundles
- Codex session history, even when stale, because it can affect local chat resume/audit history
- Codex workspaces that may contain deliverables
- Xcode Products

## Protected Data

These stay out of one-click cleanup:

- active simulator devices
- non-simulator items with open files, or whose open-file check cannot be completed
- pinned or ignored items
- Xcode archives
- dSYMs
- simulator runtimes
- simulator images
- DeviceSupport

## Execution Revalidation

Cleanup plans are advisory until execution. Immediately before each action, DELTREE rechecks the current item state and blocks the action when anything has become less safe:

- the item is now active, pinned, ignored, in a blocked domain, or no longer classified as `Safe to Remove`
- a non-simulator path no longer exists, cannot be checked for open files, or is currently open
- a simulator device is booted, no longer exists, is no longer unavailable, or cannot be safely erased
- the action is not an approved Trash, `simctl delete`, or `simctl erase` operation

## Verification

Before changing cleanup behavior, run:

```sh
xcodebuild test -scheme DELTREE -project DELTREE.xcodeproj -destination 'platform=macOS'
rg "removeItem|trashItem|simctl" DELTREE DELTREETests Tools Scripts
```

Production code should show Trash usage and approved `simctl` actions, not permanent deletion.

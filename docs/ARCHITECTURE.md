# Architecture

DELTREE uses MVVM with service protocols.

## App Shell

- `DELTREEApp` configures SwiftData and the app container.
- `AppDelegate` owns the AppKit lifecycle objects.
- `StatusItemController` owns the menu-bar status item and renders menu descriptors.
- `DashboardWindowController` hosts the SwiftUI dashboard.
- `AppUpdateService` gates Sparkle runtime updates by distribution channel and Info.plist configuration.

The app is an `LSUIElement` menu-bar app and is intentionally unsandboxed for Developer ID distribution.

## State Flow

```text
Storage scanners
    -> DefaultStorageScanner
    -> DashboardViewModel
    -> Status menu + Dashboard views
    -> SwiftData history
```

The view model owns task orchestration, throttling, scan deduping, cleanup planning, notifications, and persistence.

## Service Boundaries

Core protocols live in `StorageServiceProtocols.swift`:

- `StorageScanning`
- `DomainScanning`
- `FileSizeScanning`
- `SimctlClient`
- `SimctlCommanding`
- `AttributionTracking`
- `StorageWatching`
- `TrashServicing`
- `CleanupPlanning`
- `CleanupExecuting`
- `SnapshotPersisting`

Concrete implementations are under `DELTREE/Services`.

Sparkle is linked only by the app target. `Package.swift` keeps `DELTREECore` free of Sparkle so contributors can run core tests with `swift test`.

## UI

SwiftUI owns rendering. AppKit is used only where macOS requires it:

- `NSStatusItem`
- `NSMenu`
- Finder reveal
- Trash

The status menu is descriptor-driven so menu state can be tested without constructing AppKit menus.

## Persistence

SwiftData stores:

- scan snapshots
- storage deltas
- attribution events
- cleanup history
- manual overrides

Persisted data is local to the Mac.

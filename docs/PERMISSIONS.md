# Permissions & Troubleshooting

DELTREE scans local developer storage and prepares cleanup plans on-device. It does not require cloud credentials, upload scan inventories, or permanently remove regular files outside explicit cleanup execution.

![File access guide](assets/screenshots/permissions-file-access-guide.png)

## macOS Permissions

macOS may ask for file access when DELTREE scans folders outside its default sandbox reach, such as custom Codex workspaces, Xcode archives, or external volumes. Grant access only for locations you want DELTREE to inspect.

DELTREE checks `~/Documents/Codex` once before including it in a scan. If access is not granted, DELTREE turns off that scan root so background scans do not keep presenting the same macOS prompt. Turn on **Scan ~/Documents/Codex** in Settings to retry intentionally.

Full Disk Access is not required for the standard scan paths. If a custom location remains unreadable after a normal file-access prompt, you can either remove that location from DELTREE's scan roots or grant broader access in System Settings.

Notifications are optional. They are used for scan and cleanup completion notices, not for background tracking.

### Permissions After Rebuilding From Source

macOS tracks privacy grants against an app's code-signing identity. `make build` produces an unsigned, CI-equivalent app whose ad hoc identity changes with the executable, so a grant can be requested again after a rebuild. The fixed `build/DerivedData` path helps keep the launch location predictable but does not create a stable signing identity.

Developers who repeatedly test protected custom roots should use their own stable Apple Development identity:

```sh
DELTREE_DEVELOPMENT_SIGNING_IDENTITY="APPLE_DEVELOPMENT_CERTIFICATE_SHA1" make signed-dev-build
open build/DerivedData/Build/Products/Debug/DELTREE.app
```

Use the SHA-1 fingerprint of a local Apple Development certificate shown by `security find-identity -v -p codesigning`. Keep the same certificate and bundle identifier between builds. Do not commit a personal signing identity, certificate fingerprint, or Team ID.

An entitlements file would not grant Full Disk Access. That access is controlled by the user in System Settings, and DELTREE should request it only when a custom root cannot be read with narrower access.

## Cleanup Behavior

![Cleanup preflight](assets/screenshots/modern-cleanup-preflight.png)

DELTREE separates scanning from cleanup. A scan inventories candidate storage; cleanup requires a reviewed plan and explicit confirmation.

Only one cleanup can execute at a time. Starting cleanup closes the preflight immediately, and any work canceled during app shutdown is recorded as skipped rather than failed.

Regular files and folders are moved through macOS Trash when possible. Simulator device cleanup uses Apple's simulator tooling rather than directly removing device directories. Simulator delete and erase actions permanently remove the affected simulator data, are identified in preflight, and cannot be recovered from Trash. DELTREE records skipped items when it cannot safely classify or access a candidate.

## Common Issues

### Scan Shows Unreadable Paths

Check that the folder still exists and that DELTREE has permission to read it. For custom scan roots, remove stale paths or add the current folder again from the app.

If a previously granted custom root becomes unreadable after rebuilding from source, confirm that you used the same signed development identity and bundle identifier. Remove stale DELTREE entries from the relevant Privacy & Security pane before granting access to a differently signed build.

### Cleanup Skips an Item

Skipped cleanup usually means the item changed after the scan, is still active, or no longer matches the safety policy. Run a fresh scan before retrying.

### Trash Move Fails

Confirm the volume supports Trash and that Finder can move an item from the same folder to Trash. Network shares and external volumes can behave differently from the local startup disk.

### Legacy UI Automation Hangs

`make ui-test` is the release-gating signed launch smoke test. If you are debugging Xcode UI automation specifically, use `make xcode-ui-test`; it has a timeout wrapper because Xcode can hang while waiting for UI test workers.

## Diagnostics

For public issues, include redacted diagnostics only:

```sh
Tools/deltree diagnose --json
```

Do not paste `--raw-paths` output into public issues. Raw diagnostics can include private project names, usernames, and local directory structure.

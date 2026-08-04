# Privacy

DELTREE is designed as a local-only utility.

## What DELTREE Reads

- Known Codex and Xcode developer storage paths.
- Local Codex task/session metadata when present.
- Local process names and command lines for bounded attribution heuristics.
- File metadata such as size, dates, directory/package shape, and simulator identifiers.

## What DELTREE Stores

- Scan history and storage deltas.
- Cleanup history.
- Manual owner, pinned, and ignored overrides.
- Local attribution events used to explain recent growth.

Operational history is retained with bounded limits. Manual overrides persist until the user clears them.

## What DELTREE Does Not Do

- It does not upload scan results, cleanup history, paths, account data, or project metadata.
- It does not crawl the full disk by default.
- It does not permanently delete files in v1.
- It does not perform silent cleanup.

## Permissions

DELTREE is intended for Developer ID distribution outside the Mac App Store because it needs to inspect developer folders and move approved items to Trash. macOS may still prompt for access when protected folders are involved.

## Reports

When filing issues, redact private project names, usernames, and paths unless they are necessary for reproducing the problem. Prefer `Tools/deltree --dry-run --json` output after removing sensitive path segments.

# CLI

`Tools/deltree` is a small local inventory helper intended for diagnostics and scripted dry runs.

## Usage

```sh
Tools/deltree --dry-run
Tools/deltree --dry-run --json
Tools/deltree --dry-run --json --redact
Tools/deltree diagnose --json
```

## Install

```sh
Scripts/install-cli.sh
```

Override the destination:

```sh
DELTREE_CLI_INSTALL_DIR="$HOME/bin" Scripts/install-cli.sh
```

## Behavior

The CLI scans bounded developer roots and reports sizes. It never deletes files.

Inventory output preserves raw local paths by default because it is intended for local scripting. Add `--redact` when pasting output into an issue.

`Tools/deltree diagnose` is intended for shareable support reports. It is a dry run and redacts paths, usernames, email-like strings, UUIDs, DerivedData hashes, temporary folders, and Codex session identifiers by default. Use `--raw-paths` only for private debugging where exact paths are required.

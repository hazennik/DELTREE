# CLI

`Tools/deltree` is a small local inventory helper intended for diagnostics and scripted dry runs.

## Usage

```sh
Tools/deltree --dry-run
Tools/deltree --dry-run --json
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

The JSON output is useful for attaching diagnostic summaries to issues or release checks.


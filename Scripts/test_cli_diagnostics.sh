#!/usr/bin/env zsh
set -euo pipefail

root="${0:A:h:h}"
cli="$root/Tools/deltree"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/deltree-cli-diagnostics.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

home="$temp_dir/home"
mkdir -p "$home/.codex"
mkdir -p "$home/Library/Developer/Xcode/DerivedData/SecretApp-1234567890abcdef"
printf 'cache\n' >"$home/.codex/session-1234567890abcdef.log"
printf 'index\n' >"$home/Library/Developer/Xcode/DerivedData/SecretApp-1234567890abcdef/file"

diagnostics="$(HOME="$home" USER="ryan" "$cli" diagnose --json)"
printf '%s' "$diagnostics" | grep -Fq '"command":"diagnose"'
printf '%s' "$diagnostics" | grep -Fq '"redacted":true'
printf '%s' "$diagnostics" | grep -Fq '"path":"~/.codex"'
if printf '%s' "$diagnostics" | grep -Fq "$home"; then
  echo "Diagnose JSON leaked the raw HOME path." >&2
  exit 1
fi
if printf '%s' "$diagnostics" | grep -Fq '1234567890abcdef'; then
  echo "Diagnose JSON leaked a DerivedData/session identifier." >&2
  exit 1
fi

raw_diagnostics="$(HOME="$home" USER="ryan" "$cli" diagnose --json --raw-paths)"
printf '%s' "$raw_diagnostics" | grep -Fq '"redacted":false'
printf '%s' "$raw_diagnostics" | grep -Fq "$home/.codex"

raw_inventory="$(HOME="$home" USER="ryan" "$cli" --dry-run --json)"
printf '%s' "$raw_inventory" | grep -Fq '"command":"inventory"'
printf '%s' "$raw_inventory" | grep -Fq "$home/.codex"

redacted_inventory="$(HOME="$home" USER="ryan" "$cli" --dry-run --json --redact)"
printf '%s' "$redacted_inventory" | grep -Fq '"redacted":true'
printf '%s' "$redacted_inventory" | grep -Fq '"path":"~/.codex"'

echo "CLI diagnostics tests passed."

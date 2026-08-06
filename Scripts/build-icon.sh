#!/usr/bin/env zsh
set -euo pipefail

mode="write"
if (($#)); then
  case "$1" in
    --check)
      mode="check"
      ;;
    --write)
      mode="write"
      ;;
    -h|--help)
      echo "Usage: Scripts/build-icon.sh [--write|--check]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
fi

root="${0:A:h:h}"
source_icon_dir="$root/DELTREE/Assets.xcassets/AppIcon.appiconset"
source_preview="$root/docs/assets/deltree-icon-preview.png"

if [[ "$mode" == "write" ]]; then
  swift "$root/Scripts/build-icon.swift" \
    --output-dir "$source_icon_dir" \
    --preview "$source_preview"
  exit 0
fi

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/deltree-icon-check.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

swift "$root/Scripts/build-icon.swift" \
  --output-dir "$temp_dir/AppIcon.appiconset" \
  --preview "$temp_dir/deltree-icon-preview.png" >/dev/null

diff -qr "$temp_dir/AppIcon.appiconset" "$source_icon_dir" >/dev/null
cmp "$temp_dir/deltree-icon-preview.png" "$source_preview" >/dev/null

echo "Icon assets are up to date."

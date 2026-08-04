#!/usr/bin/env zsh
set -euo pipefail

mode="${1:-lint}"

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool is required. Install with: brew install $tool" >&2
    exit 127
  fi
}

case "$mode" in
  lint)
    require_tool swiftformat
    require_tool swiftlint
    swiftformat DELTREE DELTREETests DELTREEUITests Tests --config .swiftformat --lint
    swiftlint lint --config .swiftlint.yml
    ;;
  format)
    require_tool swiftformat
    swiftformat DELTREE DELTREETests DELTREEUITests Tests --config .swiftformat
    ;;
  *)
    echo "Usage: Scripts/lint.sh [lint|format]" >&2
    exit 2
    ;;
esac

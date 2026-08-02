#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
install_dir="${DELTREE_CLI_INSTALL_DIR:-/usr/local/bin}"

mkdir -p "$install_dir"
ln -sf "$repo_root/Tools/deltree" "$install_dir/deltree"
echo "Installed deltree CLI at $install_dir/deltree"

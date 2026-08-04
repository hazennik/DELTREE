#!/usr/bin/env zsh
set -euo pipefail

root="${0:A:h:h}"
check_script="$root/Scripts/check-repository-size.sh"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/deltree-repository-size.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

new_repo() {
  local repo="$temp_dir/repo-$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  printf '%s\n' "$repo"
}

run_check() {
  local repo="$1"
  DELTREE_REPOSITORY_CHECK_ROOT="$repo" DELTREE_REPOSITORY_MAX_BYTES="${2:-2097152}" zsh "$check_script" >/dev/null
}

expect_failure() {
  local repo="$1"
  local max_bytes="${2:-2097152}"
  if run_check "$repo" "$max_bytes" 2>/dev/null; then
    echo "Repository check unexpectedly passed for $repo" >&2
    exit 1
  fi
}

repo="$(new_repo clean)"
printf 'print("ok")\n' >"$repo/main.swift"
git -C "$repo" add main.swift
run_check "$repo"

repo="$(new_repo app)"
mkdir -p "$repo/Build/DELTREE.app/Contents/MacOS"
printf 'binary\n' >"$repo/Build/DELTREE.app/Contents/MacOS/DELTREE"
git -C "$repo" add Build/DELTREE.app
expect_failure "$repo"

repo="$(new_repo derived-data)"
mkdir -p "$repo/DerivedData/Module.noindex"
printf 'index\n' >"$repo/DerivedData/Module.noindex/file"
git -C "$repo" add DerivedData
expect_failure "$repo"

repo="$(new_repo large)"
printf '%*s\n' 256 '' | tr ' ' x >"$repo/large.bin"
git -C "$repo" add large.bin
expect_failure "$repo" 128

repo="$(new_repo allowlist)"
printf '%*s\n' 256 '' | tr ' ' x >"$repo/large.bin"
printf 'large.bin # fixture intentionally exceeds test byte limit\n' >"$repo/.repository-size-allowlist"
git -C "$repo" add large.bin .repository-size-allowlist
run_check "$repo" 128

echo "Repository size tests passed."

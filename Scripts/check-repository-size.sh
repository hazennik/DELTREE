#!/usr/bin/env zsh
set -euo pipefail

root_dir="${DELTREE_REPOSITORY_CHECK_ROOT:-${0:A:h:h}}"
max_bytes="${DELTREE_REPOSITORY_MAX_BYTES:-2097152}"
allowlist_file="${DELTREE_REPOSITORY_ALLOWLIST:-$root_dir/.repository-size-allowlist}"
failures=0
tracked_files=0

is_allowlisted() {
  local tracked_file="$1"

  [[ -f "$allowlist_file" ]] || return 1
  while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    pattern="${pattern%%#*}"
    pattern="${pattern#"${pattern%%[![:space:]]*}"}"
    pattern="${pattern%"${pattern##*[![:space:]]}"}"
    [[ -n "$pattern" ]] || continue
    if [[ "$tracked_file" == ${~pattern} ]]; then
      return 0
    fi
  done <"$allowlist_file"

  return 1
}

tracked_file_size() {
  local tracked_file="$1"
  local absolute_file="$root_dir/$tracked_file"

  if [[ -f "$absolute_file" ]]; then
    wc -c <"$absolute_file" | tr -d '[:space:]'
    return 0
  fi

  git -C "$root_dir" cat-file -s ":$tracked_file" 2>/dev/null || printf '0'
}

cd "$root_dir"

while IFS= read -r -d '' tracked_file; do
  tracked_files=$((tracked_files + 1))
  if is_allowlisted "$tracked_file"; then
    continue
  fi

  case "$tracked_file" in
    .build|.build/*|build/DerivedData|build/DerivedData/*|DerivedData|DerivedData/*|*/DerivedData/*|\
    *.app|*.app/*|*.dSYM|*.dSYM/*|*.xcarchive|*.xcarchive/*|*.xcresult|*.xcresult/*|\
    *.ipa|*.zip|*.delta|*.dmg|*.pkg|*.tar.gz|*.tgz)
      printf 'ERROR: generated artifact is tracked: %s\n' "$tracked_file" >&2
      failures=$((failures + 1))
      ;;
  esac

  size="$(tracked_file_size "$tracked_file")"
  if [[ "$size" == <-> ]] && ((size > max_bytes)); then
    printf 'ERROR: tracked file exceeds %d bytes: %s (%d bytes)\n' "$max_bytes" "$tracked_file" "$size" >&2
    failures=$((failures + 1))
  fi
done < <(git -C "$root_dir" ls-files -z)

if ((failures > 0)); then
  printf 'Repository artifact check failed with %d violation(s).\n' "$failures" >&2
  printf 'Keep generated release/build artifacts outside Git or add a narrow allowlist entry with justification.\n' >&2
  exit 1
fi

printf 'repository artifacts OK: %d tracked files, maximum %d bytes each\n' "$tracked_files" "$max_bytes"

#!/usr/bin/env zsh
set -euo pipefail

workflow_dir=".github/workflows"

ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path); puts "YAML ok: #{path}" }' "$workflow_dir"/*.yml

uses_lines="$(grep -R -nE 'uses:[[:space:]]*[^[:space:]#]+@' "$workflow_dir" || true)"
if [[ -z "$uses_lines" ]]; then
  exit 0
fi

unpinned="$(
  print -r -- "$uses_lines" | awk '
    {
      ref = $0
      sub(/^.*uses:[[:space:]]*/, "", ref)
      sub(/[[:space:]]*#.*/, "", ref)
      split(ref, parts, "@")
      if (parts[2] !~ /^[0-9a-f]{40}$/) {
        print $0
      }
    }
  '
)"

missing_version_comment="$(
  print -r -- "$uses_lines" | awk '
    {
      ref = $0
      sub(/^.*uses:[[:space:]]*/, "", ref)
      sub(/[[:space:]]*#.*/, "", ref)
      split(ref, parts, "@")
      if (parts[2] ~ /^[0-9a-f]{40}$/ && $0 !~ /#[[:space:]]*v[0-9]/) {
        print $0
      }
    }
  '
)"

if [[ -n "$unpinned" ]]; then
  echo "GitHub Actions must be pinned to full commit SHAs:" >&2
  print -r -- "$unpinned" >&2
  exit 1
fi

if [[ -n "$missing_version_comment" ]]; then
  echo "Pinned GitHub Actions must include a version comment, such as # v4:" >&2
  print -r -- "$missing_version_comment" >&2
  exit 1
fi

#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/stage-prerelease-feed.sh <tag> [--repo OWNER/REPO] [--local-dir DIR] [--output PATH] [--skip-network]

Validates a published DELTREE release candidate and stages its exact appcast
for the GitHub Pages prerelease channel. By default the verified appcast is
written to:

  docs/prerelease/appcast.xml

Use --local-dir only for tests or for already-downloaded release assets.
EOF
}

if (($# == 0)); then
  usage >&2
  exit 2
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

tag="$1"
shift
repo="${GITHUB_REPOSITORY:-hazennik/DELTREE}"
local_dir=""
output_path=""
skip_network=0

while (($#)); do
  case "$1" in
    --repo)
      shift
      repo="${1:-}"
      ;;
    --local-dir)
      shift
      local_dir="${1:-}"
      ;;
    --output)
      shift
      output_path="${1:-}"
      ;;
    --skip-network)
      skip_network=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ ! "$tag" =~ '^v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$' ]]; then
  echo "Prerelease feed tags must look like v1.0.0-rc.1: $tag" >&2
  exit 2
fi

if [[ -z "$repo" ]]; then
  echo "--repo requires OWNER/REPO." >&2
  exit 2
fi

script_dir="${0:A:h}"
repo_root="${script_dir:h}"
output_path="${output_path:-$repo_root/docs/prerelease/appcast.xml}"
output_path="${output_path:A}"
temporary_asset_dir=""
temporary_output=""

cleanup() {
  if [[ -n "$temporary_asset_dir" ]]; then
    rm -rf "$temporary_asset_dir"
  fi
  if [[ -n "$temporary_output" ]]; then
    rm -f "$temporary_output"
  fi
}
trap cleanup EXIT

if [[ -n "$local_dir" ]]; then
  asset_dir="${local_dir:A}"
  check_args=("$tag" --repo "$repo" --local-dir "$asset_dir")
else
  temporary_asset_dir="$(mktemp -d "${TMPDIR:-/tmp}/deltree-prerelease-feed.XXXXXX")"
  asset_dir="$temporary_asset_dir"
  check_args=("$tag" --repo "$repo" --download-dir "$asset_dir")
fi

if ((skip_network)); then
  check_args+=(--skip-network)
fi

zsh "$script_dir/check-release-assets.sh" "${check_args[@]}"

source_appcast="$asset_dir/appcast.xml"
if [[ ! -s "$source_appcast" ]]; then
  echo "Verified release appcast is missing: $source_appcast" >&2
  exit 1
fi

mkdir -p "${output_path:h}"
temporary_output="$(mktemp "${output_path:h}/.appcast.xml.XXXXXX")"
cp "$source_appcast" "$temporary_output"
chmod 0644 "$temporary_output"
mv "$temporary_output" "$output_path"
temporary_output=""

if ! cmp -s "$source_appcast" "$output_path"; then
  echo "Staged appcast does not match the verified release asset." >&2
  exit 1
fi

echo "Verified prerelease feed staged for $tag: $output_path"
echo "Commit this file through a protected pull request before update testing."

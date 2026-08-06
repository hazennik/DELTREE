#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/release-preflight.sh <tag> [--repo OWNER/REPO] [--post-publish] [--skip-network] [--skip-checks]

Runs the release-candidate gate from a single command. By default it verifies
the local branch is clean, validates the changelog, and runs the full local
release dry-run checks. With --post-publish it also verifies the published
GitHub Release assets, appcast enclosure, checksums, notarization, and live URLs.
EOF
}

if (($# == 0)); then
  usage >&2
  exit 2
fi

tag="$1"
shift
repo="${GITHUB_REPOSITORY:-hazennik/DELTREE}"
post_publish=0
skip_network=0
skip_checks=0

while (($#)); do
  case "$1" in
    --repo)
      if (($# < 2)); then
        echo "--repo requires OWNER/REPO." >&2
        exit 2
      fi
      shift
      repo="$1"
      ;;
    --post-publish)
      post_publish=1
      ;;
    --skip-network)
      skip_network=1
      ;;
    --skip-checks)
      skip_checks=1
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

script_dir="${0:A:h}"
repo_root="${script_dir:h}"

if [[ -z "$repo" ]]; then
  echo "--repo requires OWNER/REPO." >&2
  exit 2
fi

if [[ "$tag" != v* ]]; then
  echo "Release tag must start with v, for example v1.0.0-rc.1." >&2
  exit 1
fi

cd "$repo_root"

if ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
  echo "Working tree must be clean before release preflight." >&2
  exit 1
fi

Scripts/validate-changelog.sh "$tag" \
  --notes-output build/release/release-notes.md \
  --html-output build/release/release-notes.html

if ((skip_checks == 0)); then
  make check
fi

make package-check
make appcast-check
make spark-sign-check

if ((post_publish == 1)); then
  release_args=( "$tag" --repo "$repo" )
  if ((skip_network == 1)); then
    release_args+=( --skip-network )
  fi
  Scripts/check-release-assets.sh "${release_args[@]}"
fi

echo "Release preflight passed for $tag."

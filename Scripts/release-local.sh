#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/release-local.sh <tag> [--repo OWNER/REPO] [--env-file PATH] [--draft] [--no-publish] [--skip-checks]

Builds, signs, notarizes, appcast-signs, and optionally publishes a DELTREE
Developer ID release from this Mac using local-only credentials.

The local env file defaults to:
  ~/.config/deltree/release.env

The release tag must already exist locally and be present on the GitHub remote
before publishing.
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
env_file="${DELTREE_LOCAL_RELEASE_ENV:-$HOME/.config/deltree/release.env}"
draft=0
publish=1
skip_checks=0

while (($#)); do
  case "$1" in
    --repo)
      shift
      repo="${1:-}"
      ;;
    --env-file)
      shift
      env_file="${1:-}"
      ;;
    --draft)
      draft=1
      ;;
    --no-publish)
      publish=0
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
cd "$repo_root"

if [[ "$tag" != v* ]]; then
  echo "Release tag must start with v, for example v1.0.0-rc.1." >&2
  exit 2
fi

if [[ -z "$repo" || -z "$env_file" ]]; then
  echo "--repo and --env-file must not be empty." >&2
  exit 2
fi

if ! git rev-parse --verify --quiet "refs/tags/$tag" >/dev/null; then
  echo "Release tag does not exist locally: $tag" >&2
  exit 2
fi

tag_commit="$(git rev-list -n 1 "$tag")"
head_commit="$(git rev-parse HEAD)"
if [[ "$tag_commit" != "$head_commit" ]]; then
  echo "Current checkout does not match $tag." >&2
  echo "Check out the tagged commit before releasing:" >&2
  echo "  git checkout $tag" >&2
  exit 2
fi

if ((publish)) && ! git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
  echo "Release tag is not on origin yet. Push it first:" >&2
  echo "  git push origin $tag" >&2
  exit 2
fi

if ((skip_checks)); then
  Scripts/release-preflight.sh "$tag" --repo "$repo" --skip-checks
else
  Scripts/release-preflight.sh "$tag" --repo "$repo"
fi

Scripts/setup-local-release-secrets.sh --env-file "$env_file"

set -a
source "$env_file"
set +a

version="${tag#v}"
marketing_version="${version%%-*}"
build_version="${DELTREE_BUILD_VERSION:-$(git rev-list --count "$tag")}"
release_zip_url="${DELTREE_RELEASE_ZIP_URL:-https://github.com/$repo/releases/download/$tag/DELTREE.zip}"

mkdir -p build/release

Scripts/validate-changelog.sh "$tag" \
  --notes-output build/release/release-notes.md \
  --html-output build/release/release-notes.html

DELTREE_RELEASE_VERSION="$version" \
DELTREE_MARKETING_VERSION="$marketing_version" \
DELTREE_BUILD_VERSION="$build_version" \
Scripts/package-release.sh --notarize --distribution developer-id

Scripts/sign-sparkle-update.sh \
  --zip build/export/DELTREE.zip \
  --env-output build/release/sparkle.env

source build/release/sparkle.env

DELTREE_RELEASE_VERSION="$version" \
DELTREE_MARKETING_VERSION="$marketing_version" \
DELTREE_BUILD_VERSION="$build_version" \
DELTREE_RELEASE_ZIP_URL="$release_zip_url" \
DELTREE_RELEASE_NOTES_HTML_PATH="build/release/release-notes.html" \
Scripts/generate-appcast.sh

if ((publish == 0)); then
  cat <<EOF
Local release artifacts are ready:
  build/export/DELTREE.zip
  build/export/DELTREE.zip.sha256
  build/export/DELTREE.dSYM.zip
  build/export/DELTREE.dSYM.zip.sha256
  build/export/appcast.xml
EOF
  exit 0
fi

release_args=(
  release create "$tag"
  build/export/DELTREE.zip
  build/export/DELTREE.zip.sha256
  build/export/DELTREE.dSYM.zip
  build/export/DELTREE.dSYM.zip.sha256
  build/export/appcast.xml
  --repo "$repo"
  --title "DELTREE $version"
  --notes-file build/release/release-notes.md
  --verify-tag
)

if ((draft)); then
  release_args+=(--draft)
fi

gh "${release_args[@]}"

if ((draft == 0)); then
  Scripts/check-release-assets.sh "$tag" --repo "$repo"
fi

echo "Local release complete for $tag."

#!/usr/bin/env zsh
set -euo pipefail

if (($# != 2)); then
  echo "Usage: Scripts/validate-sparkle-feed-url.sh <tag> <feed-url>" >&2
  exit 2
fi

tag="$1"
feed_url="$2"

if [[ "$tag" != v* ]]; then
  echo "Release tag must start with v: $tag" >&2
  exit 2
fi

if [[ "$feed_url" != https://* ]]; then
  echo "Sparkle feed URL must use HTTPS: $feed_url" >&2
  exit 2
fi

version="${tag#v}"
if [[ "$version" == *-* && "$feed_url" == */releases/latest/download/* ]]; then
  echo "Prerelease builds cannot use GitHub's releases/latest feed URL because GitHub excludes prereleases from that redirect." >&2
  echo "Configure DELTREE_SPARKLE_FEED_URL with a stable prerelease-channel appcast URL." >&2
  exit 2
fi

echo "Sparkle feed URL is valid for $tag."

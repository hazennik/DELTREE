#!/usr/bin/env zsh
set -euo pipefail

validator="Scripts/validate-sparkle-feed-url.sh"
ga_feed="https://github.com/hazennik/DELTREE/releases/latest/download/appcast.xml"
prerelease_feed="https://hazennik.github.io/DELTREE/prerelease/appcast.xml"

zsh "$validator" v1.0.0 "$ga_feed" >/dev/null
zsh "$validator" v1.0.0-rc.1 "$prerelease_feed" >/dev/null

if zsh "$validator" v1.0.0-rc.1 "$ga_feed" >/dev/null 2>&1; then
  echo "Expected the GA-only latest-release feed to fail for a prerelease." >&2
  exit 1
fi

if zsh "$validator" v1.0.0 "http://example.com/appcast.xml" >/dev/null 2>&1; then
  echo "Expected a non-HTTPS feed to fail." >&2
  exit 1
fi

echo "Sparkle feed URL tests passed."

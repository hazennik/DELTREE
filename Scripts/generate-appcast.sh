#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/generate-appcast.sh [--dry-run]

Generates a Sparkle appcast XML file for the current DELTREE release artifact.

Environment:
  DELTREE_RELEASE_VERSION      Short version string. Defaults to the current git tag or 1.0.
  DELTREE_RELEASE_BUILD        Build number. Defaults to 1.
  DELTREE_RELEASE_ZIP_PATH     Local zip path. Defaults to build/export/DELTREE.zip.
  DELTREE_RELEASE_ZIP_URL      Public release zip URL. Required unless --dry-run is used.
  DELTREE_SPARKLE_SIGNATURE    Sparkle EdDSA signature. Required unless --dry-run is used.
  DELTREE_APPCAST_OUTPUT       Output XML path. Defaults to build/export/appcast.xml.

Generate DELTREE_SPARKLE_SIGNATURE with Sparkle's sign_update tool after creating
the final notarized zip.
EOF
}

xml_escape() {
  sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e 's/"/\&quot;/g' \
    -e "s/'/\&apos;/g"
}

dry_run=0

while (($#)); do
  case "$1" in
    --dry-run)
      dry_run=1
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

if [[ -n "${DELTREE_RELEASE_VERSION:-}" ]]; then
  version="$DELTREE_RELEASE_VERSION"
else
  version="$(git describe --tags --exact-match 2>/dev/null | sed 's/^v//' || true)"
  version="${version:-1.0}"
fi

build="${DELTREE_RELEASE_BUILD:-1}"
zip_path="${DELTREE_RELEASE_ZIP_PATH:-build/export/DELTREE.zip}"
zip_url="${DELTREE_RELEASE_ZIP_URL:-}"
signature="${DELTREE_SPARKLE_SIGNATURE:-}"
output="${DELTREE_APPCAST_OUTPUT:-build/export/appcast.xml}"

if ((dry_run)); then
  zip_url="${zip_url:-https://example.com/DELTREE.zip}"
  signature="${signature:-dry-run-signature}"
fi

if [[ -z "$zip_url" ]]; then
  echo "Set DELTREE_RELEASE_ZIP_URL before generating the appcast." >&2
  exit 2
fi

if [[ -z "$signature" ]]; then
  echo "Set DELTREE_SPARKLE_SIGNATURE or generate it with Sparkle's sign_update tool." >&2
  exit 2
fi

if [[ -f "$zip_path" ]]; then
  length="$(stat -f%z "$zip_path")"
else
  if ((dry_run)); then
    length=0
  else
    echo "Release zip not found at $zip_path." >&2
    exit 2
  fi
fi

pub_date="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S %z')"
escaped_version="$(printf '%s' "$version" | xml_escape)"
escaped_build="$(printf '%s' "$build" | xml_escape)"
escaped_zip_url="$(printf '%s' "$zip_url" | xml_escape)"
escaped_signature="$(printf '%s' "$signature" | xml_escape)"
escaped_pub_date="$(printf '%s' "$pub_date" | xml_escape)"
mkdir -p "$(dirname "$output")"

cat >"$output" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>DELTREE Updates</title>
    <item>
      <title>Version $escaped_version</title>
      <sparkle:version>$escaped_build</sparkle:version>
      <sparkle:shortVersionString>$escaped_version</sparkle:shortVersionString>
      <pubDate>$escaped_pub_date</pubDate>
      <enclosure
        url="$escaped_zip_url"
        sparkle:edSignature="$escaped_signature"
        sparkle:version="$escaped_build"
        length="$length"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
EOF

echo "Created $output"

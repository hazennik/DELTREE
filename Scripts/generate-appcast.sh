#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/generate-appcast.sh [--dry-run]

Generates the Sparkle appcast XML for the current DELTREE release artifact.

Environment:
  DELTREE_RELEASE_VERSION          Display release version. Defaults to current git tag or 1.0.0.
  DELTREE_MARKETING_VERSION        CFBundleShortVersionString. Defaults to DELTREE_RELEASE_VERSION without prerelease suffix.
  DELTREE_BUILD_VERSION            CFBundleVersion / sparkle:version. Defaults to DELTREE_RELEASE_BUILD or 1.
  DELTREE_RELEASE_ZIP_PATH         Local zip path. Defaults to build/export/DELTREE.zip.
  DELTREE_RELEASE_ZIP_URL          Public release zip URL. Required unless --dry-run is used.
  DELTREE_SPARKLE_SIGNATURE        Sparkle EdDSA signature. Required unless --dry-run is used.
  DELTREE_RELEASE_NOTES_HTML_PATH  Optional changelog-derived HTML notes.
  DELTREE_EXISTING_APPCAST_PATH    Optional appcast to check for duplicate builds.
  DELTREE_APPCAST_OUTPUT           Output XML path. Defaults to build/export/appcast.xml.

Generate DELTREE_SPARKLE_SIGNATURE with Scripts/sign-sparkle-update.sh after
creating the final notarized zip.
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

cdata_escape() {
  sed 's/]]>/]]]]><![CDATA[>/g'
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
  release_version="$DELTREE_RELEASE_VERSION"
else
  release_version="$(git describe --tags --exact-match 2>/dev/null | sed 's/^v//' || true)"
  release_version="${release_version:-1.0.0}"
fi

marketing_version="${DELTREE_MARKETING_VERSION:-${release_version%%-*}}"
build_version="${DELTREE_BUILD_VERSION:-${DELTREE_RELEASE_BUILD:-1}}"
zip_path="${DELTREE_RELEASE_ZIP_PATH:-build/export/DELTREE.zip}"
zip_url="${DELTREE_RELEASE_ZIP_URL:-}"
signature="${DELTREE_SPARKLE_SIGNATURE:-}"
notes_html_path="${DELTREE_RELEASE_NOTES_HTML_PATH:-}"
existing_appcast_path="${DELTREE_EXISTING_APPCAST_PATH:-}"
output="${DELTREE_APPCAST_OUTPUT:-build/export/appcast.xml}"
minimum_system_version="${DELTREE_MINIMUM_SYSTEM_VERSION:-14.0}"

if ((dry_run)); then
  zip_url="${zip_url:-https://example.com/DELTREE.zip}"
  signature="${signature:-dry-run-signature}"
fi

if [[ -z "$zip_url" ]]; then
  echo "Set DELTREE_RELEASE_ZIP_URL before generating the appcast." >&2
  exit 2
fi

if [[ -z "$signature" ]]; then
  echo "Set DELTREE_SPARKLE_SIGNATURE or generate it with Scripts/sign-sparkle-update.sh." >&2
  exit 2
fi

if [[ "$build_version" != <-> ]]; then
  echo "DELTREE_BUILD_VERSION must be a monotonically increasing integer for Sparkle." >&2
  exit 2
fi

if [[ -n "$existing_appcast_path" && -f "$existing_appcast_path" ]]; then
  if ruby -rrexml/document - "$existing_appcast_path" "$build_version" <<'RUBY'
path, build = ARGV
doc = REXML::Document.new(File.read(path))
duplicate = REXML::XPath.match(doc, "//sparkle:version", { "sparkle" => "http://www.andymatuschak.org/xml-namespaces/sparkle" })
  .any? { |element| element.text.to_s.strip == build }
exit(duplicate ? 0 : 1)
RUBY
  then
    echo "Appcast already contains sparkle:version $build_version: $existing_appcast_path" >&2
    exit 1
  fi
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

notes_html=""
if [[ -n "$notes_html_path" ]]; then
  if [[ ! -f "$notes_html_path" ]]; then
    echo "Release notes HTML not found at $notes_html_path." >&2
    exit 2
  fi
  notes_html="$(cdata_escape <"$notes_html_path")"
fi

pub_date="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S %z')"
escaped_release_version="$(printf '%s' "$release_version" | xml_escape)"
escaped_marketing_version="$(printf '%s' "$marketing_version" | xml_escape)"
escaped_build_version="$(printf '%s' "$build_version" | xml_escape)"
escaped_zip_url="$(printf '%s' "$zip_url" | xml_escape)"
escaped_signature="$(printf '%s' "$signature" | xml_escape)"
escaped_pub_date="$(printf '%s' "$pub_date" | xml_escape)"
escaped_minimum_system_version="$(printf '%s' "$minimum_system_version" | xml_escape)"
mkdir -p "$(dirname "$output")"

{
  cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>DELTREE Updates</title>
    <item>
      <title>Version $escaped_release_version</title>
      <sparkle:version>$escaped_build_version</sparkle:version>
      <sparkle:shortVersionString>$escaped_marketing_version</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$escaped_minimum_system_version</sparkle:minimumSystemVersion>
      <pubDate>$escaped_pub_date</pubDate>
EOF
  if [[ -n "$notes_html" ]]; then
    cat <<EOF
      <description><![CDATA[
$notes_html
      ]]></description>
EOF
  fi
  cat <<EOF
      <enclosure
        url="$escaped_zip_url"
        sparkle:edSignature="$escaped_signature"
        length="$length"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
EOF
} >"$output"

echo "Created $output"

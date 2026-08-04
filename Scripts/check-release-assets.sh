#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/check-release-assets.sh <tag> [--repo OWNER/REPO] [--local-dir DIR] [--download-dir DIR] [--skip-network]

Verifies published DELTREE release assets after a GitHub Release is created.

Required assets:
  DELTREE.zip
  DELTREE.zip.sha256
  DELTREE.dSYM.zip
  DELTREE.dSYM.zip.sha256
  appcast.xml

When --local-dir is omitted, the script uses gh to download assets from the
release. Codesign, notarization, stapling, URL, checksum, zip, and appcast
checks run against the downloaded assets.
EOF
}

if (($# == 0)); then
  usage >&2
  exit 2
fi

tag="$1"
shift
repo="${GITHUB_REPOSITORY:-hazennik/DELTREE}"
local_dir=""
download_dir=""
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
    --download-dir)
      shift
      download_dir="${1:-}"
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

script_dir="${0:A:h}"
repo_root="${script_dir:h}"
source "$repo_root/Scripts/release-artifacts.sh"

if [[ -z "$repo" ]]; then
  echo "--repo requires OWNER/REPO." >&2
  exit 2
fi

required_assets=(
  DELTREE.zip
  DELTREE.zip.sha256
  DELTREE.dSYM.zip
  DELTREE.dSYM.zip.sha256
  appcast.xml
)

if [[ -n "$local_dir" ]]; then
  asset_dir="$local_dir"
else
  gh_bin="${GH_BIN:-gh}"
  asset_dir="${download_dir:-$(mktemp -d "${TMPDIR:-/tmp}/deltree-release-assets.XXXXXX")}"
  mkdir -p "$asset_dir"

  assets="$("$gh_bin" release view "$tag" --repo "$repo" --json assets --jq '.assets[].name')"
  for asset in "${required_assets[@]}"; do
    if ! print -r -- "$assets" | grep -Fxq "$asset"; then
      echo "Release $tag is missing asset: $asset" >&2
      exit 1
    fi
  done

  "$gh_bin" release download "$tag" \
    --repo "$repo" \
    --dir "$asset_dir" \
    --pattern 'DELTREE.zip' \
    --pattern 'DELTREE.zip.sha256' \
    --pattern 'DELTREE.dSYM.zip' \
    --pattern 'DELTREE.dSYM.zip.sha256' \
    --pattern 'appcast.xml' \
    --clobber
fi

for asset in "${required_assets[@]}"; do
  if [[ ! -s "$asset_dir/$asset" ]]; then
    echo "Release asset is missing or empty: $asset_dir/$asset" >&2
    exit 1
  fi
done

verify_checksum() {
  local artifact="$1"
  local checksum="$2"
  local expected
  local actual

  expected="$(awk '{ print $1 }' "$checksum" | head -1)"
  actual="$(shasum -a 256 "$artifact" | awk '{ print $1 }')"
  if [[ -z "$expected" || "$expected" != "$actual" ]]; then
    echo "SHA-256 mismatch for $(basename "$artifact")." >&2
    exit 1
  fi
}

verify_checksum "$asset_dir/DELTREE.zip" "$asset_dir/DELTREE.zip.sha256"
verify_checksum "$asset_dir/DELTREE.dSYM.zip" "$asset_dir/DELTREE.dSYM.zip.sha256"

deltree_verify_zip_metadata_clean "$asset_dir/DELTREE.zip"
deltree_verify_zip_metadata_clean "$asset_dir/DELTREE.dSYM.zip"

zipinfo_bin="${ZIPINFO_BIN:-/usr/bin/zipinfo}"
"$zipinfo_bin" -t "$asset_dir/DELTREE.zip" >/dev/null
"$zipinfo_bin" -t "$asset_dir/DELTREE.dSYM.zip" >/dev/null

expected_zip_url="${DELTREE_RELEASE_ZIP_URL:-https://github.com/$repo/releases/download/$tag/DELTREE.zip}"
if ((skip_network == 0)); then
  curl_bin="${CURL_BIN:-/usr/bin/curl}"
  "$curl_bin" -fsIL "$expected_zip_url" >/dev/null
  "$curl_bin" -fsIL "https://github.com/$repo/releases/download/$tag/DELTREE.dSYM.zip" >/dev/null
  "$curl_bin" -fsIL "https://github.com/$repo/releases/download/$tag/appcast.xml" >/dev/null
fi

ruby -rrexml/document - "$asset_dir/appcast.xml" "$expected_zip_url" "$asset_dir/DELTREE.zip" <<'RUBY'
appcast_path, expected_url, zip_path = ARGV
doc = REXML::Document.new(File.read(appcast_path))
namespace = { "sparkle" => "http://www.andymatuschak.org/xml-namespaces/sparkle" }
item = REXML::XPath.first(doc, "/rss/channel/item")
abort "Appcast has no release item." unless item
version = REXML::XPath.first(item, "sparkle:version", namespace)&.text.to_s.strip
short_version = REXML::XPath.first(item, "sparkle:shortVersionString", namespace)&.text.to_s.strip
minimum_system = REXML::XPath.first(item, "sparkle:minimumSystemVersion", namespace)&.text.to_s.strip
enclosure = item.elements["enclosure"]
abort "Appcast item has no enclosure." unless enclosure
abort "Appcast sparkle:version is missing." if version.empty?
abort "Appcast sparkle:shortVersionString is missing." if short_version.empty?
abort "Appcast minimum macOS version is missing." if minimum_system.empty?
abort "Appcast enclosure URL mismatch: #{enclosure.attributes["url"]}" unless enclosure.attributes["url"] == expected_url
abort "Appcast enclosure signature is missing." if enclosure.attributes["sparkle:edSignature"].to_s.empty?
actual_length = File.size(zip_path).to_s
abort "Appcast length mismatch: #{enclosure.attributes["length"]} != #{actual_length}" unless enclosure.attributes["length"] == actual_length
RUBY

extract_dir="$(mktemp -d "${TMPDIR:-/tmp}/deltree-release-extract.XXXXXX")"
trap 'rm -rf "$extract_dir"' EXIT
ditto_bin="${DITTO_BIN:-/usr/bin/ditto}"
"$ditto_bin" -x -k "$asset_dir/DELTREE.zip" "$extract_dir"
app_path="$extract_dir/DELTREE.app"
if [[ ! -d "$app_path" ]]; then
  echo "DELTREE.zip did not extract DELTREE.app." >&2
  exit 1
fi

deltree_verify_notarized_app "$app_path"

echo "Release assets verified for $tag."

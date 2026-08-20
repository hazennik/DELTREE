#!/usr/bin/env zsh
set -euo pipefail

root="${0:A:h:h}"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/deltree-release-pipeline-tests.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

zsh "$root/Scripts/validate-changelog.sh" v1.0.0-rc.1 \
  --notes-output "$temp_dir/release-notes.md" \
  --html-output "$temp_dir/release-notes.html" \
  --env-output "$temp_dir/release.env" >/dev/null

grep -Fq 'Initial LSUIElement menu-bar app shell.' "$temp_dir/release-notes.md"
grep -Fq '<h3>Added</h3>' "$temp_dir/release-notes.html"
grep -Fq 'DELTREE_RELEASE_VERSION=1.0.0-rc.1' "$temp_dir/release.env"
grep -Fq 'DELTREE_MARKETING_VERSION=1.0.0' "$temp_dir/release.env"

if zsh "$root/Scripts/validate-changelog.sh" v9.9.9 2>/dev/null; then
  echo "Missing changelog release unexpectedly passed validation." >&2
  exit 1
fi

bin_dir="$temp_dir/bin"
mkdir -p "$bin_dir"
log="$temp_dir/calls.log"
: >"$log"

mock_tool() {
  local name="$1"
  local body="$2"
  local tool_path="$bin_dir/$name"
  {
    print -r -- '#!/usr/bin/env zsh'
    print -r -- 'set -euo pipefail'
    print -r -- "log_file=\"$log\""
    print -r -- "$body"
  } >"$tool_path"
  chmod +x "$tool_path"
}

mock_tool sign_update '
print -r -- "sign_update $*" >>"$log_file"
case "$*" in
  *--verify*) exit 0 ;;
  *) print -r -- "sparkle:edSignature=\"mock-signature\" length=\"12\"" ;;
esac
'
zip_path="$temp_dir/DELTREE.zip"
printf 'fake zip data' >"$zip_path"

signature="$(DELTREE_SPARKLE_ACCOUNT=deltree \
  DELTREE_SPARKLE_SIGN_UPDATE_BIN="$bin_dir/sign_update" \
  zsh "$root/Scripts/sign-sparkle-update.sh" --zip "$zip_path" --signature-only)"
[[ "$signature" == "mock-signature" ]]
grep -Fq -- 'sign_update ' "$log"
grep -Fq -- '--account deltree' "$log"
grep -Fq -- '--verify' "$log"
grep -Fq -- 'mock-signature' "$log"

DELTREE_RELEASE_VERSION=1.0.0-rc.1 \
DELTREE_MARKETING_VERSION=1.0.0 \
DELTREE_BUILD_VERSION=42 \
DELTREE_RELEASE_ZIP_PATH="$zip_path" \
DELTREE_RELEASE_ZIP_URL="https://github.com/hazennik/DELTREE/releases/download/v1.0.0-rc.1/DELTREE.zip" \
DELTREE_SPARKLE_SIGNATURE="$signature" \
DELTREE_RELEASE_NOTES_HTML_PATH="$temp_dir/release-notes.html" \
DELTREE_APPCAST_OUTPUT="$temp_dir/appcast.xml" \
zsh "$root/Scripts/generate-appcast.sh" >/dev/null

grep -Fq '<sparkle:version>42</sparkle:version>' "$temp_dir/appcast.xml"
grep -Fq '<sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>' "$temp_dir/appcast.xml"
grep -Fq 'sparkle:edSignature="mock-signature"' "$temp_dir/appcast.xml"
grep -Fq '<description><![CDATA[' "$temp_dir/appcast.xml"

if DELTREE_BUILD_VERSION=42 \
  DELTREE_RELEASE_ZIP_PATH="$zip_path" \
  DELTREE_RELEASE_ZIP_URL="https://example.com/DELTREE.zip" \
  DELTREE_SPARKLE_SIGNATURE="$signature" \
  DELTREE_EXISTING_APPCAST_PATH="$temp_dir/appcast.xml" \
  DELTREE_APPCAST_OUTPUT="$temp_dir/duplicate.xml" \
  zsh "$root/Scripts/generate-appcast.sh" 2>/dev/null; then
  echo "Duplicate appcast build unexpectedly passed validation." >&2
  exit 1
fi

asset_dir="$temp_dir/assets"
mkdir -p "$asset_dir"
cp "$zip_path" "$asset_dir/DELTREE.zip"
printf 'fake dsym zip data' >"$asset_dir/DELTREE.dSYM.zip"
shasum -a 256 "$asset_dir/DELTREE.zip" | awk '{ print $1 "  DELTREE.zip" }' >"$asset_dir/DELTREE.zip.sha256"
shasum -a 256 "$asset_dir/DELTREE.dSYM.zip" | awk '{ print $1 "  DELTREE.dSYM.zip" }' >"$asset_dir/DELTREE.dSYM.zip.sha256"
cp "$temp_dir/appcast.xml" "$asset_dir/appcast.xml"

mock_tool zipinfo '
print -r -- "zipinfo $*" >>"$log_file"
case "$1" in
  -t) exit 0 ;;
  -1) exit 1 ;;
  *) exit 0 ;;
esac
'
mock_tool ditto '
print -r -- "ditto $*" >>"$log_file"
destination="${@: -1}"
mkdir -p "$destination/DELTREE.app"
'
mock_tool xattr 'print -r -- "xattr $*" >>"$log_file"; exit 1'
mock_tool codesign 'print -r -- "codesign $*" >>"$log_file"; exit 0'
mock_tool syspolicy_check 'print -r -- "syspolicy_check $*" >>"$log_file"; exit 0'
mock_tool stapler 'print -r -- "stapler $*" >>"$log_file"; exit 0'

ZIPINFO_BIN="$bin_dir/zipinfo" \
DITTO_BIN="$bin_dir/ditto" \
XATTR_BIN="$bin_dir/xattr" \
CODESIGN_BIN="$bin_dir/codesign" \
SYSPOLICY_CHECK_BIN="$bin_dir/syspolicy_check" \
STAPLER_BIN="$bin_dir/stapler" \
zsh "$root/Scripts/check-release-assets.sh" v1.0.0-rc.1 \
  --repo hazennik/DELTREE \
  --local-dir "$asset_dir" \
  --skip-network >/dev/null

grep -Fq 'stapler validate' "$log"

digest="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
zsh "$root/Scripts/generate-homebrew-cask.sh" \
  --version 1.0.0 \
  --sha256 "$digest" \
  --output "$temp_dir/deltree.rb" >/dev/null
grep -Fq 'DELTREE-homebrew.zip' "$temp_dir/deltree.rb"
grep -Fq "sha256 \"$digest\"" "$temp_dir/deltree.rb"

if zsh "$root/Scripts/generate-homebrew-cask.sh" \
  --version 1.0.0 \
  --sha256 "$digest" \
  --url "https://github.com/hazennik/DELTREE/releases/download/v1.0.0/DELTREE.zip" >/dev/null 2>&1; then
  echo "Homebrew cask unexpectedly accepted the Developer ID artifact URL." >&2
  exit 1
fi

echo "Release pipeline tests passed."

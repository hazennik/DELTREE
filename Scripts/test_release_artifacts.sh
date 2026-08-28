#!/usr/bin/env zsh
set -euo pipefail

root="${0:A:h:h}"
source "$root/Scripts/release-artifacts.sh"

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/deltree-release-tests.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

bin_dir="$temp_dir/bin"
app="$temp_dir/DELTREE.app"
archive="$temp_dir/DELTREE.xcarchive"
dsym="$archive/dSYMs/DELTREE.app.dSYM"
sparkle="$app/Contents/Frameworks/Sparkle.framework/Versions/B"
log="$temp_dir/calls.log"
mkdir -p "$bin_dir" "$app/Contents/MacOS" "$app/Contents/Resources" "$dsym/Contents/Resources/DWARF"
mkdir -p "$sparkle/XPCServices/Downloader.xpc" "$sparkle/XPCServices/Installer.xpc" "$sparkle/Updater.app"
ln -s B "$app/Contents/Frameworks/Sparkle.framework/Versions/Current"
: >"$app/Contents/MacOS/DELTREE"
print -r -- 'MIT License' >"$app/Contents/Resources/DELTREE-LICENSE.txt"
print -r -- 'Copyright (c) 2026 Ryan Nicoletti' >>"$app/Contents/Resources/DELTREE-LICENSE.txt"
print -r -- 'Copyright (c) 2006-2013 Andy Matuschak.' >"$app/Contents/Resources/Sparkle-LICENSE.txt"
print -r -- 'bspatch.c and bsdiff.c' >>"$app/Contents/Resources/Sparkle-LICENSE.txt"
: >"$sparkle/Autoupdate"
: >"$dsym/Contents/Resources/DWARF/DELTREE"
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

mock_tool ditto 'print -r -- "ditto $*" >>"$log_file"; : >"${@: -1}"'
mock_tool codesign 'print -r -- "codesign $*" >>"$log_file"; exit 0'
mock_tool codesign_fail 'print -r -- "codesign_fail $*" >>"$log_file"; exit 1'
mock_tool xattr 'print -r -- "xattr $*" >>"$log_file"; exit 1'
mock_tool xattr_quarantined 'print -r -- "xattr_quarantined $*" >>"$log_file"; print -r -- "0081;fake;Safari;https://example.invalid"; exit 0'
mock_tool syspolicy_check 'print -r -- "syspolicy_check $*" >>"$log_file"; exit 0'
mock_tool spctl 'print -r -- "spctl $*" >>"$log_file"; exit 0'
mock_tool stapler 'print -r -- "stapler $*" >>"$log_file"; exit 0'
mock_tool stapler_fail 'print -r -- "stapler_fail $*" >>"$log_file"; exit 1'
mock_tool zipinfo '
print -r -- "zipinfo $*" >>"$log_file"
case "$*" in
  *forbidden.zip*) print -r -- "__MACOSX/._DELTREE"; exit 0 ;;
  *) exit 1 ;;
esac
'
mock_tool dwarfdump '
print -r -- "dwarfdump $*" >>"$log_file"
print -r -- "UUID: AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE (arm64) $2"
print -r -- "UUID: FFFFFFFF-1111-2222-3333-444444444444 (x86_64) $2"
'
mock_tool dwarfdump_mismatch '
print -r -- "dwarfdump_mismatch $*" >>"$log_file"
case "$*" in
  *DELTREE.app.dSYM/Contents/Resources/DWARF/DELTREE*)
    print -r -- "UUID: 00000000-1111-2222-3333-444444444444 (arm64) $2"
    ;;
  *)
    print -r -- "UUID: AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE (arm64) $2"
    ;;
esac
'

export DITTO_BIN="$bin_dir/ditto"
export CODESIGN_BIN="$bin_dir/codesign"
export XATTR_BIN="$bin_dir/xattr"
export SYSPOLICY_CHECK_BIN="$bin_dir/syspolicy_check"
export SPCTL_BIN="$bin_dir/spctl"
export STAPLER_BIN="$bin_dir/stapler"
export DWARFDUMP_BIN="$bin_dir/dwarfdump"
export ZIPINFO_BIN="$bin_dir/zipinfo"

[[ "$(deltree_app_zip_path "$temp_dir")" == "$temp_dir/DELTREE.zip" ]]
[[ "$(deltree_app_zip_path "$temp_dir" homebrew)" == "$temp_dir/DELTREE-homebrew.zip" ]]
[[ "$(deltree_dsym_zip_path "$temp_dir")" == "$temp_dir/DELTREE.dSYM.zip" ]]
[[ "$(deltree_sha256_path "$temp_dir/DELTREE.zip")" == "$temp_dir/DELTREE.zip.sha256" ]]

deltree_create_zip "$app" "$temp_dir/DELTREE.zip"
grep -Fq -- 'ditto --norsrc -c -k --keepParent' "$log"

deltree_write_sha256 "$temp_dir/DELTREE.zip"
grep -Eq '^[0-9a-f]{64}  DELTREE.zip$' "$temp_dir/DELTREE.zip.sha256"

: >"$temp_dir/forbidden.zip"
if deltree_verify_zip_metadata_clean "$temp_dir/forbidden.zip" 2>/dev/null; then
  echo "Zip with AppleDouble metadata unexpectedly passed verification." >&2
  exit 1
fi

[[ "$(deltree_locate_app_dsym "$archive")" == "$dsym" ]]
[[ "$(deltree_dsym_dwarf_binary_path "$dsym")" == "$dsym/Contents/Resources/DWARF/DELTREE" ]]
deltree_verify_dsym_uuids "$app/Contents/MacOS/DELTREE" "$dsym"
deltree_package_dsym "$archive" "$app" "$temp_dir"
grep -Fq -- 'dwarfdump --uuid' "$log"
grep -Fq -- 'DELTREE.dSYM.zip' "$log"

export DWARFDUMP_BIN="$bin_dir/dwarfdump_mismatch"
if deltree_verify_dsym_uuids "$app/Contents/MacOS/DELTREE" "$dsym" 2>/dev/null; then
  echo "Mismatched dSYM unexpectedly passed UUID verification." >&2
  exit 1
fi
export DWARFDUMP_BIN="$bin_dir/dwarfdump"

if deltree_locate_app_dsym "$temp_dir/Missing.xcarchive" 2>/dev/null; then
  echo "Missing dSYM unexpectedly passed discovery." >&2
  exit 1
fi

deltree_verify_packaged_app "$app"
grep -Fq -- 'codesign --verify --deep --strict --verbose=2' "$log"

mv "$app/Contents/Resources/Sparkle-LICENSE.txt" "$app/Contents/Resources/Sparkle-LICENSE.missing"
if deltree_verify_packaged_app "$app" 2>/dev/null; then
  echo "App without third-party notices unexpectedly passed verification." >&2
  exit 1
fi
mv "$app/Contents/Resources/Sparkle-LICENSE.missing" "$app/Contents/Resources/Sparkle-LICENSE.txt"

mv "$app/Contents/Resources/DELTREE-LICENSE.txt" "$app/Contents/Resources/DELTREE-LICENSE.missing"
if deltree_verify_packaged_app "$app" 2>/dev/null; then
  echo "App without its DELTREE license unexpectedly passed verification." >&2
  exit 1
fi
mv "$app/Contents/Resources/DELTREE-LICENSE.missing" "$app/Contents/Resources/DELTREE-LICENSE.txt"

deltree_codesign_developer_id_app "$app" "Developer ID Application: Example"
grep -Fq -- 'codesign --force --options runtime --timestamp --sign Developer ID Application: Example' "$log"
grep -Fq -- 'Sparkle.framework/Versions/Current/XPCServices/Downloader.xpc' "$log"
grep -Fq -- 'Sparkle.framework/Versions/Current/XPCServices/Installer.xpc' "$log"
grep -Fq -- 'Sparkle.framework/Versions/Current/Updater.app' "$log"
grep -Fq -- 'Sparkle.framework/Versions/Current/Autoupdate' "$log"
grep -Fq -- 'Sparkle.framework' "$log"

export XATTR_BIN="$bin_dir/xattr_quarantined"
if deltree_verify_packaged_app "$app" 2>/dev/null; then
  echo "Quarantined app unexpectedly passed verification." >&2
  exit 1
fi
export XATTR_BIN="$bin_dir/xattr"

export CODESIGN_BIN="$bin_dir/codesign_fail"
if deltree_verify_packaged_app "$app" 2>/dev/null; then
  echo "App with failed codesign unexpectedly passed verification." >&2
  exit 1
fi
export CODESIGN_BIN="$bin_dir/codesign"

deltree_verify_notarized_app "$app"
grep -Fq -- 'syspolicy_check distribution' "$log"
grep -Fq -- 'stapler validate' "$log"

export STAPLER_BIN="$bin_dir/stapler_fail"
if deltree_verify_notarized_app "$app" 2>/dev/null; then
  echo "App with failed stapler validation unexpectedly passed verification." >&2
  exit 1
fi
export STAPLER_BIN="$bin_dir/stapler"

echo "Release artifact tests passed."

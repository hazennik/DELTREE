#!/usr/bin/env zsh
set -euo pipefail

root="${0:A:h:h}"
source "$root/Scripts/release-artifacts.sh"

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/deltree-release-tests.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

bin_dir="$temp_dir/bin"
app="$temp_dir/DELTREE.app"
log="$temp_dir/calls.log"
mkdir -p "$bin_dir" "$app/Contents/MacOS"
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

mock_tool ditto 'print -r -- "ditto $*" >>"$log_file"'
mock_tool codesign 'print -r -- "codesign $*" >>"$log_file"; exit 0'
mock_tool codesign_fail 'print -r -- "codesign_fail $*" >>"$log_file"; exit 1'
mock_tool xattr 'print -r -- "xattr $*" >>"$log_file"; exit 1'
mock_tool xattr_quarantined 'print -r -- "xattr_quarantined $*" >>"$log_file"; print -r -- "0081;fake;Safari;https://example.invalid"; exit 0'
mock_tool syspolicy_check 'print -r -- "syspolicy_check $*" >>"$log_file"; exit 0'
mock_tool spctl 'print -r -- "spctl $*" >>"$log_file"; exit 0'
mock_tool stapler 'print -r -- "stapler $*" >>"$log_file"; exit 0'
mock_tool stapler_fail 'print -r -- "stapler_fail $*" >>"$log_file"; exit 1'

export DITTO_BIN="$bin_dir/ditto"
export CODESIGN_BIN="$bin_dir/codesign"
export XATTR_BIN="$bin_dir/xattr"
export SYSPOLICY_CHECK_BIN="$bin_dir/syspolicy_check"
export SPCTL_BIN="$bin_dir/spctl"
export STAPLER_BIN="$bin_dir/stapler"

[[ "$(deltree_app_zip_path "$temp_dir")" == "$temp_dir/DELTREE.zip" ]]
[[ "$(deltree_dsym_zip_path "$temp_dir")" == "$temp_dir/DELTREE.dSYM.zip" ]]

deltree_create_zip "$app" "$temp_dir/DELTREE.zip"
grep -Fq -- 'ditto --norsrc -c -k --keepParent' "$log"

deltree_verify_packaged_app "$app"
grep -Fq -- 'codesign --verify --deep --strict --verbose=2' "$log"

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

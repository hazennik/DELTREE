#!/usr/bin/env zsh
set -euo pipefail

script_dir="${0:A:h}"
repo_root="${script_dir:h}"

project="${PROJECT:-DELTREE.xcodeproj}"
scheme="${SCHEME:-DELTREE}"
destination="${DESTINATION:-platform=macOS,arch=arm64}"
derived_data_path="${DERIVED_DATA_PATH:-build/DerivedData}"
xcodebuild_bin="${XCODEBUILD:-xcodebuild}"
timeout_seconds="${UI_TEST_TIMEOUT_SECONDS:-120}"

"$xcodebuild_bin" build \
  -scheme "$scheme" \
  -project "$project" \
  -destination "$destination" \
  -derivedDataPath "$derived_data_path"

app_path="$repo_root/$derived_data_path/Build/Products/Debug/DELTREE.app"
if [[ ! -d "$app_path" ]]; then
  echo "Built app not found: $app_path" >&2
  exit 1
fi

lsui_element="$(/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$app_path/Contents/Info.plist")"
if [[ "$lsui_element" != "1" && "$lsui_element" != "true" ]]; then
  echo "DELTREE.app is not configured as an LSUIElement menu-bar app." >&2
  exit 1
fi

DELTREE_DISABLE_INITIAL_SCAN=1 \
DELTREE_EXIT_AFTER_LAUNCH=1 \
ruby "$repo_root/Scripts/run-with-timeout.rb" "$timeout_seconds" -- "$app_path/Contents/MacOS/DELTREE"

echo "UI launch smoke test passed."

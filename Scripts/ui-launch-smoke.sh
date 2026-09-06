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

screenshot_dir="$repo_root/build/UI-Smoke"
mkdir -p "$screenshot_dir"
find "$screenshot_dir" -maxdepth 1 -type f -name '*.png' -delete

DELTREE_DISABLE_INITIAL_SCAN=1 \
DELTREE_SCREENSHOT_OUTPUT_DIR="$screenshot_dir" \
ruby "$repo_root/Scripts/run-with-timeout.rb" "$timeout_seconds" -- "$app_path/Contents/MacOS/DELTREE"

expected_screenshots=(
  modern-dashboard.png
  modern-menu-bar-dropdown.png
  modern-cleanup-preflight.png
  modern-settings.png
  classic-dashboard.png
  classic-menu-bar-dropdown.png
  permissions-file-access-guide.png
  social-preview.png
)

for screenshot in "${expected_screenshots[@]}"; do
  screenshot_path="$screenshot_dir/$screenshot"
  if [[ ! -s "$screenshot_path" ]]; then
    echo "Rendered UI smoke image is missing or empty: $screenshot_path" >&2
    exit 1
  fi
  width="$(sips -g pixelWidth "$screenshot_path" | awk '/pixelWidth:/ { print $2 }')"
  height="$(sips -g pixelHeight "$screenshot_path" | awk '/pixelHeight:/ { print $2 }')"
  if [[ -z "$width" || -z "$height" || "$width" -lt 500 || "$height" -lt 400 ]]; then
    echo "Rendered UI smoke image has invalid dimensions: $screenshot_path (${width:-?}x${height:-?})" >&2
    exit 1
  fi
done

echo "UI launch and rendered-surface smoke tests passed."

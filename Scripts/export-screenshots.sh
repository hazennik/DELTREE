#!/usr/bin/env zsh
set -euo pipefail

script_dir="${0:A:h}"
repo_root="${script_dir:h}"

project="${PROJECT:-DELTREE.xcodeproj}"
scheme="${SCHEME:-DELTREE}"
destination="${DESTINATION:-platform=macOS,arch=arm64}"
derived_data_path="${DERIVED_DATA_PATH:-build/DerivedData}"
xcodebuild_bin="${XCODEBUILD:-xcodebuild}"
output_dir="${1:-docs/assets/screenshots}"

"$xcodebuild_bin" build \
  -scheme "$scheme" \
  -project "$project" \
  -destination "$destination" \
  -derivedDataPath "$derived_data_path"

app_path="$repo_root/$derived_data_path/Build/Products/Debug/DELTREE.app"
if [[ ! -x "$app_path/Contents/MacOS/DELTREE" ]]; then
  echo "Built app executable not found: $app_path/Contents/MacOS/DELTREE" >&2
  exit 1
fi

mkdir -p "$repo_root/$output_dir"

DELTREE_DISABLE_INITIAL_SCAN=1 \
DELTREE_SCREENSHOT_OUTPUT_DIR="$repo_root/$output_dir" \
ruby "$repo_root/Scripts/run-with-timeout.rb" 90 -- "$app_path/Contents/MacOS/DELTREE"

echo "Screenshots exported to $output_dir:"
find "$repo_root/$output_dir" -maxdepth 1 -type f -name '*.png' -print | sort

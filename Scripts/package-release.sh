#!/usr/bin/env zsh
set -euo pipefail

scheme="${DELTREE_SCHEME:-DELTREE}"
project="${DELTREE_PROJECT:-DELTREE.xcodeproj}"
archive_path="${DELTREE_ARCHIVE_PATH:-build/DELTREE.xcarchive}"
export_path="${DELTREE_EXPORT_PATH:-build/export}"
identity="${DELTREE_DEVELOPER_ID_APPLICATION:-}"
team_id="${DELTREE_TEAM_ID:-}"

if [[ -z "$identity" || -z "$team_id" ]]; then
  echo "Set DELTREE_DEVELOPER_ID_APPLICATION and DELTREE_TEAM_ID before packaging." >&2
  exit 2
fi

mkdir -p build "$export_path"

xcodebuild archive \
  -scheme "$scheme" \
  -project "$project" \
  -configuration Release \
  -archivePath "$archive_path" \
  DEVELOPMENT_TEAM="$team_id" \
  CODE_SIGN_IDENTITY="$identity"

ditto -c -k --keepParent "$archive_path/Products/Applications/DELTREE.app" "$export_path/DELTREE.zip"

cat <<EOF
Created $export_path/DELTREE.zip

Notarization is intentionally environment-driven. Submit with:
  xcrun notarytool submit "$export_path/DELTREE.zip" --keychain-profile <profile> --wait

Sparkle appcast generation requires your EdDSA key and appcast host.
EOF

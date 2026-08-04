#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/package-release.sh [--dry-run] [--notarize] [--no-notarize] [--skip-staple]

Builds the signed Developer ID archive and release zip for DELTREE.

Environment:
  DELTREE_SCHEME                       Xcode scheme. Defaults to DELTREE.
  DELTREE_PROJECT                      Xcode project. Defaults to DELTREE.xcodeproj.
  DELTREE_ARCHIVE_PATH                 Archive output. Defaults to build/DELTREE.xcarchive.
  DELTREE_EXPORT_PATH                  Export directory. Defaults to build/export.
  DELTREE_DEVELOPER_ID_APPLICATION     Developer ID Application signing identity.
  DELTREE_TEAM_ID                      Apple Developer Team ID.
  DELTREE_NOTARY_PROFILE               notarytool keychain profile.
  DELTREE_NOTARY_KEYCHAIN              Optional keychain containing the notarytool profile.

Dry runs validate arguments and print the commands without requiring Apple credentials.
EOF
}

dry_run=0
notarize=0
staple=1

while (($#)); do
  case "$1" in
    --dry-run)
      dry_run=1
      ;;
    --notarize)
      notarize=1
      ;;
    --no-notarize)
      notarize=0
      ;;
    --skip-staple)
      staple=0
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

scheme="${DELTREE_SCHEME:-DELTREE}"
project="${DELTREE_PROJECT:-DELTREE.xcodeproj}"
archive_path="${DELTREE_ARCHIVE_PATH:-build/DELTREE.xcarchive}"
export_path="${DELTREE_EXPORT_PATH:-build/export}"
identity="${DELTREE_DEVELOPER_ID_APPLICATION:-}"
team_id="${DELTREE_TEAM_ID:-}"
notary_profile="${DELTREE_NOTARY_PROFILE:-}"
notary_keychain="${DELTREE_NOTARY_KEYCHAIN:-}"
app_path="$archive_path/Products/Applications/DELTREE.app"
zip_path="$export_path/DELTREE.zip"

if ((dry_run)); then
  identity="${identity:-Developer ID Application: Example}"
  team_id="${team_id:-TEAMID1234}"
  notary_profile="${notary_profile:-deltree-notary-profile}"
fi

if [[ -z "$identity" || -z "$team_id" ]]; then
  echo "Set DELTREE_DEVELOPER_ID_APPLICATION and DELTREE_TEAM_ID before packaging." >&2
  exit 2
fi

if ((notarize)) && [[ -z "$notary_profile" ]]; then
  echo "Set DELTREE_NOTARY_PROFILE before notarizing." >&2
  exit 2
fi

mkdir -p build "$export_path"

archive_command=(
  xcodebuild archive
  -scheme "$scheme"
  -project "$project"
  -configuration Release
  -archivePath "$archive_path"
  DEVELOPMENT_TEAM="$team_id"
  CODE_SIGN_IDENTITY="$identity"
  CODE_SIGNING_ALLOWED=YES
)
zip_command=(ditto -c -k --keepParent "$app_path" "$zip_path")
notary_command=(xcrun notarytool submit "$zip_path" --keychain-profile "$notary_profile" --wait)
if [[ -n "$notary_keychain" ]]; then
  notary_command+=(--keychain "$notary_keychain")
fi

if ((dry_run)); then
  print -r -- "Dry run: ${archive_command[*]}"
  print -r -- "Dry run: ${zip_command[*]}"
  if ((notarize)); then
    print -r -- "Dry run: ${notary_command[*]}"
    if ((staple)); then
      print -r -- "Dry run: xcrun stapler staple \"$app_path\""
      print -r -- "Dry run: ${zip_command[*]}"
    fi
  fi
  print -r -- "Dry run complete."
  exit 0
fi

"${archive_command[@]}"
"${zip_command[@]}"

if ((notarize)); then
  "${notary_command[@]}"
  if ((staple)); then
    xcrun stapler staple "$app_path"
    "${zip_command[@]}"
  fi
fi

cat <<EOF
Created $zip_path

Sparkle appcast generation requires DELTREE_SPARKLE_SIGNATURE and DELTREE_RELEASE_ZIP_URL:
  Scripts/generate-appcast.sh
EOF

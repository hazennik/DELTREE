#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/package-release.sh [--dry-run] [--notarize] [--no-notarize] [--skip-staple] [--distribution developer-id|homebrew]

Builds the signed Developer ID archive and release zip for DELTREE.

Environment:
  DELTREE_SCHEME                       Xcode scheme. Defaults to DELTREE.
  DELTREE_PROJECT                      Xcode project. Defaults to DELTREE.xcodeproj.
  DELTREE_ARCHIVE_PATH                 Archive output. Defaults to build/DELTREE.xcarchive.
  DELTREE_EXPORT_PATH                  Export directory. Defaults to build/export.
  DELTREE_MARKETING_VERSION            CFBundleShortVersionString for release archives. Defaults to 1.0.0.
  DELTREE_BUILD_VERSION                CFBundleVersion for release archives. Defaults to 1.
  DELTREE_SPARKLE_FEED_URL             Sparkle feed URL embedded in Info.plist.
  DELTREE_SPARKLE_PUBLIC_ED_KEY        Sparkle public EdDSA key embedded in Info.plist.
  DELTREE_DEVELOPER_ID_APPLICATION     Developer ID Application signing identity.
  DELTREE_TEAM_ID                      Apple Developer Team ID.
  DELTREE_NOTARY_PROFILE               notarytool keychain profile.
  DELTREE_NOTARY_KEYCHAIN              Optional keychain containing the notarytool profile.

Dry runs validate arguments and print the commands without requiring Apple credentials.
Developer ID distribution is the default. Use --distribution homebrew only for Homebrew Cask artifacts.
EOF
}

dry_run=0
notarize=0
staple=1
distribution="developer-id"
script_dir="${0:A:h}"
repo_root="${script_dir:h}"
source "$repo_root/Scripts/release-artifacts.sh"

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
    --distribution)
      shift
      if (($# == 0)); then
        echo "--distribution requires developer-id or homebrew." >&2
        usage >&2
        exit 2
      fi
      distribution="$1"
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

case "$distribution" in
  developer-id|homebrew)
    ;;
  *)
    echo "Unsupported distribution: $distribution" >&2
    usage >&2
    exit 2
    ;;
esac

scheme="${DELTREE_SCHEME:-DELTREE}"
project="${DELTREE_PROJECT:-DELTREE.xcodeproj}"
archive_path="${DELTREE_ARCHIVE_PATH:-build/DELTREE.xcarchive}"
export_path="${DELTREE_EXPORT_PATH:-build/export}"
marketing_version="${DELTREE_MARKETING_VERSION:-1.0.0}"
build_version="${DELTREE_BUILD_VERSION:-1}"
sparkle_feed_url="${DELTREE_SPARKLE_FEED_URL:-https://github.com/hazennik/DELTREE/releases/latest/download/appcast.xml}"
sparkle_public_ed_key="${DELTREE_SPARKLE_PUBLIC_ED_KEY:-}"
identity="${DELTREE_DEVELOPER_ID_APPLICATION:-}"
team_id="${DELTREE_TEAM_ID:-}"
notary_profile="${DELTREE_NOTARY_PROFILE:-}"
notary_keychain="${DELTREE_NOTARY_KEYCHAIN:-}"
app_path="$archive_path/Products/Applications/DELTREE.app"
zip_path="$(deltree_app_zip_path "$export_path" "$distribution")"
dsym_zip_path="$(deltree_dsym_zip_path "$export_path")"

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
  MARKETING_VERSION="$marketing_version"
  CURRENT_PROJECT_VERSION="$build_version"
  DELTREE_DISTRIBUTION_CHANNEL="$distribution"
  DELTREE_SPARKLE_FEED_URL="$sparkle_feed_url"
  DELTREE_SPARKLE_PUBLIC_ED_KEY="$sparkle_public_ed_key"
)
notary_command=(xcrun notarytool submit "$zip_path" --keychain-profile "$notary_profile" --wait)
if [[ -n "$notary_keychain" ]]; then
  notary_command+=(--keychain "$notary_keychain")
fi

if ((dry_run)); then
  print -r -- "Dry run: ${archive_command[*]}"
  deltree_create_zip "$app_path" "$zip_path" 1
  print -r -- "Dry run: write SHA-256 \"$(deltree_sha256_path "$zip_path")\""
  deltree_package_dsym "$archive_path" "$app_path" "$export_path" 1
  print -r -- "Dry run: write SHA-256 \"$(deltree_sha256_path "$dsym_zip_path")\""
  print -r -- "Dry run: verify packaged app \"$app_path\""
  if ((notarize)); then
    print -r -- "Dry run: ${notary_command[*]}"
    if ((staple)); then
      print -r -- "Dry run: xcrun stapler staple \"$app_path\""
      print -r -- "Dry run: verify notarized app \"$app_path\""
      deltree_create_zip "$app_path" "$zip_path" 1
      print -r -- "Dry run: write SHA-256 \"$(deltree_sha256_path "$zip_path")\""
    fi
  fi
  print -r -- "Dry run complete."
  exit 0
fi

"${archive_command[@]}"
deltree_create_zip "$app_path" "$zip_path"
deltree_package_dsym "$archive_path" "$app_path" "$export_path"
deltree_write_sha256 "$zip_path"
deltree_write_sha256 "$dsym_zip_path"
deltree_verify_packaged_app "$app_path"

if ((notarize)); then
  "${notary_command[@]}"
  if ((staple)); then
    xcrun stapler staple "$app_path"
    deltree_verify_notarized_app "$app_path"
    deltree_create_zip "$app_path" "$zip_path"
    deltree_write_sha256 "$zip_path"
  fi
fi

cat <<EOF
Created $zip_path
Created $(deltree_sha256_path "$zip_path")
Created $dsym_zip_path
Created $(deltree_sha256_path "$dsym_zip_path")

Sparkle appcast generation requires a signature from Scripts/sign-sparkle-update.sh and DELTREE_RELEASE_ZIP_URL:
  Scripts/generate-appcast.sh
EOF

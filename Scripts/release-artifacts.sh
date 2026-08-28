#!/usr/bin/env zsh

deltree_app_zip_path() {
  local export_path="$1"
  local distribution="${2:-developer-id}"

  case "$distribution" in
    homebrew)
      printf '%s/DELTREE-homebrew.zip\n' "$export_path"
      ;;
    *)
      printf '%s/DELTREE.zip\n' "$export_path"
      ;;
  esac
}

deltree_dsym_zip_path() {
  local export_path="$1"
  printf '%s/DELTREE.dSYM.zip\n' "$export_path"
}

deltree_sha256_path() {
  local artifact_path="$1"
  printf '%s.sha256\n' "$artifact_path"
}

deltree_write_sha256() {
  local artifact_path="$1"
  local checksum_path="${2:-$(deltree_sha256_path "$artifact_path")}"

  if [[ ! -f "$artifact_path" ]]; then
    echo "Cannot checksum missing artifact: $artifact_path" >&2
    return 1
  fi

  shasum -a 256 "$artifact_path" | awk -v name="$(basename "$artifact_path")" '{ print $1 "  " name }' >"$checksum_path"
}

deltree_zip_has_forbidden_metadata() {
  local zip_path="$1"
  local zipinfo_bin="${ZIPINFO_BIN:-/usr/bin/zipinfo}"

  "$zipinfo_bin" -1 "$zip_path" | awk '
    /(^|\/)\._/ { print; found = 1 }
    /^__MACOSX\// { print; found = 1 }
    END { exit found ? 0 : 1 }
  '
}

deltree_verify_zip_metadata_clean() {
  local zip_path="$1"
  local forbidden

  forbidden="$(deltree_zip_has_forbidden_metadata "$zip_path" || true)"
  if [[ -n "$forbidden" ]]; then
    {
      echo "Zip contains unsafe AppleDouble or __MACOSX metadata: $zip_path"
      print -r -- "$forbidden"
    } >&2
    return 1
  fi
}

deltree_create_zip() {
  local source_path="$1"
  local zip_path="$2"
  local dry_run="${3:-0}"
  local ditto_bin="${DITTO_BIN:-/usr/bin/ditto}"

  if [[ "$dry_run" == "1" ]]; then
    print -r -- "Dry run: $ditto_bin --norsrc -c -k --keepParent \"$source_path\" \"$zip_path\""
    return 0
  fi

  rm -f "$zip_path"
  "$ditto_bin" --norsrc -c -k --keepParent "$source_path" "$zip_path"
  deltree_verify_zip_metadata_clean "$zip_path"
}

deltree_locate_app_dsym() {
  local archive_path="$1"
  local expected="$archive_path/dSYMs/DELTREE.app.dSYM"

  if [[ -d "$expected" ]]; then
    print -r -- "$expected"
    return 0
  fi

  echo "DELTREE dSYM not found at $expected." >&2
  return 1
}

deltree_dsym_dwarf_binary_path() {
  local dsym_path="$1"
  printf '%s/Contents/Resources/DWARF/DELTREE\n' "$dsym_path"
}

deltree_dwarf_uuids() {
  local binary_path="$1"
  local dwarfdump_bin="${DWARFDUMP_BIN:-/usr/bin/dwarfdump}"

  "$dwarfdump_bin" --uuid "$binary_path" | awk '
    /^UUID:/ {
      uuid = toupper($2)
      arch = $3
      gsub(/[()]/, "", arch)
      if (uuid != "" && arch != "") {
        print arch " " uuid
      }
    }
  ' | sort
}

deltree_verify_dsym_uuids() {
  local app_binary="$1"
  local dsym_path="$2"
  local dsym_binary
  local app_uuids
  local dsym_uuids

  dsym_binary="$(deltree_dsym_dwarf_binary_path "$dsym_path")"
  if [[ ! -f "$app_binary" ]]; then
    echo "App binary not found at $app_binary." >&2
    return 1
  fi
  if [[ ! -f "$dsym_binary" ]]; then
    echo "dSYM DWARF binary not found at $dsym_binary." >&2
    return 1
  fi

  app_uuids="$(deltree_dwarf_uuids "$app_binary")"
  dsym_uuids="$(deltree_dwarf_uuids "$dsym_binary")"

  if [[ -z "$app_uuids" ]]; then
    echo "No DWARF UUIDs found in app binary at $app_binary." >&2
    return 1
  fi
  if [[ -z "$dsym_uuids" ]]; then
    echo "No DWARF UUIDs found in dSYM at $dsym_binary." >&2
    return 1
  fi
  if [[ "$app_uuids" != "$dsym_uuids" ]]; then
    {
      echo "dSYM UUIDs do not match the app binary."
      echo "App binary UUIDs:"
      print -r -- "$app_uuids"
      echo "dSYM UUIDs:"
      print -r -- "$dsym_uuids"
    } >&2
    return 1
  fi
}

deltree_package_dsym() {
  local archive_path="$1"
  local app_path="$2"
  local export_path="$3"
  local dry_run="${4:-0}"
  local dsym_zip_path
  local app_binary
  local dsym_path

  dsym_zip_path="$(deltree_dsym_zip_path "$export_path")"
  app_binary="$app_path/Contents/MacOS/DELTREE"

  if [[ "$dry_run" == "1" ]]; then
    dsym_path="$archive_path/dSYMs/DELTREE.app.dSYM"
    print -r -- "Dry run: verify dSYM UUIDs \"$app_binary\" \"$dsym_path\""
    deltree_create_zip "$dsym_path" "$dsym_zip_path" 1
    return 0
  fi

  dsym_path="$(deltree_locate_app_dsym "$archive_path")" || return 1
  deltree_verify_dsym_uuids "$app_binary" "$dsym_path" || return 1
  deltree_create_zip "$dsym_path" "$dsym_zip_path"
}

deltree_verify_no_quarantine_attribute() {
  local bundle="$1"
  local xattr_bin="${XATTR_BIN:-/usr/bin/xattr}"
  local quarantined

  quarantined="$("$xattr_bin" -r -p com.apple.quarantine "$bundle" 2>/dev/null || true)"
  if [[ -n "$quarantined" ]]; then
    echo "Packaged app still has com.apple.quarantine: $bundle" >&2
    return 1
  fi
}

deltree_verify_codesign() {
  local bundle="$1"
  local codesign_bin="${CODESIGN_BIN:-/usr/bin/codesign}"

  "$codesign_bin" --verify --deep --strict --verbose=2 "$bundle"
}

deltree_verify_license_notices() {
  local bundle="$1"
  local deltree_license="$bundle/Contents/Resources/DELTREE-LICENSE.txt"
  local sparkle_license="$bundle/Contents/Resources/Sparkle-LICENSE.txt"

  if [[ ! -s "$deltree_license" ]]; then
    echo "DELTREE license notice is missing from the app bundle: $deltree_license" >&2
    return 1
  fi

  if ! grep -Fq 'MIT License' "$deltree_license" || \
     ! grep -Fq 'Copyright (c) 2026 Ryan Nicoletti' "$deltree_license"; then
    echo "DELTREE license notice is incomplete: $deltree_license" >&2
    return 1
  fi

  if [[ ! -s "$sparkle_license" ]]; then
    echo "Sparkle license notice is missing from the app bundle: $sparkle_license" >&2
    return 1
  fi

  if ! grep -Fq 'Copyright (c) 2006-2013 Andy Matuschak.' "$sparkle_license" || \
     ! grep -Fq 'bspatch.c and bsdiff.c' "$sparkle_license"; then
    echo "Sparkle license notice is incomplete: $sparkle_license" >&2
    return 1
  fi
}

deltree_codesign_developer_id_item() {
  local item="$1"
  local identity="$2"
  local dry_run="${3:-0}"
  local codesign_bin="${CODESIGN_BIN:-/usr/bin/codesign}"
  local -a command=(
    "$codesign_bin"
    --force
    --options runtime
    --timestamp
    --sign "$identity"
    "$item"
  )

  if [[ "$dry_run" == "1" ]]; then
    print -r -- "Dry run: ${command[*]}"
    return 0
  fi

  "${command[@]}"
}

deltree_codesign_developer_id_app() {
  local bundle="$1"
  local identity="$2"
  local dry_run="${3:-0}"
  local sparkle_framework="$bundle/Contents/Frameworks/Sparkle.framework"
  local sparkle_version="$sparkle_framework/Versions/Current"
  local -a sparkle_items
  local item

  if [[ -z "$identity" ]]; then
    echo "Developer ID signing identity is required." >&2
    return 1
  fi

  if [[ -d "$sparkle_framework" ]]; then
    if [[ ! -d "$sparkle_version" ]]; then
      sparkle_version="$sparkle_framework/Versions/B"
    fi

    sparkle_items=(
      "$sparkle_version/XPCServices/Downloader.xpc"
      "$sparkle_version/XPCServices/Installer.xpc"
      "$sparkle_version/Updater.app"
      "$sparkle_version/Autoupdate"
      "$sparkle_framework"
    )

    for item in "${sparkle_items[@]}"; do
      if [[ -e "$item" || -L "$item" ]]; then
        deltree_codesign_developer_id_item "$item" "$identity" "$dry_run" || return 1
      fi
    done
  fi

  deltree_codesign_developer_id_item "$bundle" "$identity" "$dry_run"
}

deltree_verify_distribution_policy() {
  local bundle="$1"
  local syspolicy_bin="${SYSPOLICY_CHECK_BIN:-/usr/bin/syspolicy_check}"
  local spctl_bin="${SPCTL_BIN:-/usr/sbin/spctl}"

  if [[ -x "$syspolicy_bin" ]]; then
    "$syspolicy_bin" distribution "$bundle"
  else
    "$spctl_bin" -a -t exec -vv "$bundle"
  fi
}

deltree_verify_stapled_notarization() {
  local bundle="$1"
  local stapler_bin="${STAPLER_BIN:-/usr/bin/xcrun stapler}"

  ${=stapler_bin} validate "$bundle"
}

deltree_verify_packaged_app() {
  local bundle="$1"

  deltree_verify_license_notices "$bundle" || return 1
  deltree_verify_no_quarantine_attribute "$bundle" || return 1
  deltree_verify_codesign "$bundle" || return 1
}

deltree_verify_notarized_app() {
  local bundle="$1"

  deltree_verify_packaged_app "$bundle" || return 1
  deltree_verify_distribution_policy "$bundle" || return 1
  deltree_verify_stapled_notarization "$bundle" || return 1
}

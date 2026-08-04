#!/usr/bin/env zsh

deltree_app_zip_path() {
  local export_path="$1"
  printf '%s/DELTREE.zip\n' "$export_path"
}

deltree_dsym_zip_path() {
  local export_path="$1"
  printf '%s/DELTREE.dSYM.zip\n' "$export_path"
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

  deltree_verify_no_quarantine_attribute "$bundle" || return 1
  deltree_verify_codesign "$bundle" || return 1
}

deltree_verify_notarized_app() {
  local bundle="$1"

  deltree_verify_packaged_app "$bundle" || return 1
  deltree_verify_distribution_policy "$bundle" || return 1
  deltree_verify_stapled_notarization "$bundle" || return 1
}

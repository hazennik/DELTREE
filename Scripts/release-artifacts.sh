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

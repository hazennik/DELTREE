#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/sign-sparkle-update.sh [--zip PATH] [--dry-run] [--env-output PATH] [--signature-only]

Signs the final notarized DELTREE zip with Sparkle's sign_update tool and
extracts the EdDSA signature for appcast generation.

Environment:
  DELTREE_SPARKLE_SIGN_UPDATE_BIN       Explicit path to sign_update.
  DELTREE_SPARKLE_ACCOUNT               Optional Sparkle Keychain account.
  DELTREE_SPARKLE_PRIVATE_KEY_FILE      Sparkle EdDSA private key file.
  DELTREE_SPARKLE_PRIVATE_KEY_BASE64    Base64-encoded private key file contents.
  DELTREE_RELEASE_ZIP_PATH              Zip path. Defaults to build/export/DELTREE.zip.
EOF
}

zip_path="${DELTREE_RELEASE_ZIP_PATH:-build/export/DELTREE.zip}"
dry_run=0
env_output=""
signature_only=0

while (($#)); do
  case "$1" in
    --zip)
      shift
      zip_path="${1:-}"
      ;;
    --dry-run)
      dry_run=1
      ;;
    --env-output)
      shift
      env_output="${1:-}"
      ;;
    --signature-only)
      signature_only=1
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

if [[ -z "$zip_path" ]]; then
  echo "--zip requires a path." >&2
  exit 2
fi

locate_sign_update() {
  if [[ -n "${DELTREE_SPARKLE_SIGN_UPDATE_BIN:-}" ]]; then
    if [[ -x "$DELTREE_SPARKLE_SIGN_UPDATE_BIN" ]]; then
      print -r -- "$DELTREE_SPARKLE_SIGN_UPDATE_BIN"
      return 0
    fi
    echo "DELTREE_SPARKLE_SIGN_UPDATE_BIN is not executable: $DELTREE_SPARKLE_SIGN_UPDATE_BIN" >&2
    return 1
  fi

  if command -v sign_update >/dev/null 2>&1; then
    command -v sign_update
    return 0
  fi

  local candidate
  candidate="$(find build/DerivedData "$HOME/Library/Developer/Xcode/DerivedData" \
    -path '*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update' \
    -perm +111 -print -quit 2>/dev/null || true)"
  if [[ -n "$candidate" ]]; then
    print -r -- "$candidate"
    return 0
  fi

  echo "Could not find Sparkle sign_update. Resolve Xcode packages or set DELTREE_SPARKLE_SIGN_UPDATE_BIN." >&2
  return 1
}

if ((dry_run)); then
  signature="dry-run-sparkle-signature"
  if ((signature_only)); then
    print -r -- "$signature"
  else
    print -r -- "Dry run: sign Sparkle update \"$zip_path\""
    print -r -- "DELTREE_SPARKLE_SIGNATURE=$signature"
  fi
  if [[ -n "$env_output" ]]; then
    print -r -- "DELTREE_SPARKLE_SIGNATURE=$signature" >>"$env_output"
  fi
  exit 0
fi

if [[ ! -f "$zip_path" ]]; then
  echo "Release zip not found at $zip_path." >&2
  exit 1
fi

sign_update_bin="$(locate_sign_update)"
temporary_key_file=""
cleanup() {
  if [[ -n "$temporary_key_file" ]]; then
    rm -f "$temporary_key_file"
  fi
}
trap cleanup EXIT

key_file="${DELTREE_SPARKLE_PRIVATE_KEY_FILE:-}"
if [[ -z "$key_file" && -n "${DELTREE_SPARKLE_PRIVATE_KEY_BASE64:-}" ]]; then
  temporary_key_file="$(mktemp "${TMPDIR:-/tmp}/deltree-sparkle-key.XXXXXX")"
  printf '%s' "$DELTREE_SPARKLE_PRIVATE_KEY_BASE64" | base64 --decode >"$temporary_key_file"
  chmod 600 "$temporary_key_file"
  key_file="$temporary_key_file"
fi

sign_command=("$sign_update_bin")
if [[ -n "${DELTREE_SPARKLE_ACCOUNT:-}" ]]; then
  sign_command+=(--account "$DELTREE_SPARKLE_ACCOUNT")
fi
if [[ -n "$key_file" ]]; then
  if [[ ! -f "$key_file" ]]; then
    echo "Sparkle private key file not found: $key_file" >&2
    exit 1
  fi
  sign_command+=(--ed-key-file "$key_file")
fi
sign_command+=("$zip_path")

signature_output="$("${sign_command[@]}")"
signature="$(print -r -- "$signature_output" | sed -nE 's/.*sparkle:edSignature="([^"]+)".*/\1/p' | head -1)"
if [[ -z "$signature" ]]; then
  echo "Could not parse Sparkle EdDSA signature from sign_update output." >&2
  print -r -- "$signature_output" >&2
  exit 1
fi

"$sign_update_bin" --verify "$zip_path" "$signature" >/dev/null

if [[ -n "$env_output" ]]; then
  print -r -- "DELTREE_SPARKLE_SIGNATURE=$signature" >>"$env_output"
fi

if ((signature_only)); then
  print -r -- "$signature"
else
  print -r -- "DELTREE_SPARKLE_SIGNATURE=$signature"
fi

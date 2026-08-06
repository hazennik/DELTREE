#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/setup-local-release-secrets.sh [--env-file PATH] [--print-template]

Validates DELTREE's local-only release configuration and stores the App Store
Connect notarization key in the macOS Keychain through xcrun notarytool.

Environment file defaults to:
  ~/.config/deltree/release.env

Required environment:
  DELTREE_TEAM_ID
  DELTREE_DEVELOPER_ID_APPLICATION
  DELTREE_NOTARY_PROFILE
  DELTREE_APP_STORE_CONNECT_KEY_ID
  DELTREE_APP_STORE_CONNECT_ISSUER_ID
  DELTREE_APP_STORE_CONNECT_API_KEY_FILE
  DELTREE_SPARKLE_PUBLIC_ED_KEY

Optional environment:
  DELTREE_NOTARY_KEYCHAIN
  DELTREE_SPARKLE_ACCOUNT
  DELTREE_SPARKLE_PRIVATE_KEY_FILE
EOF
}

print_template() {
  cat <<'EOF'
# Save as ~/.config/deltree/release.env, then run:
#   chmod 600 ~/.config/deltree/release.env
#
# Keep referenced private files outside the repository.

export DELTREE_TEAM_ID="TEAMID1234"
export DELTREE_DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name or Company (TEAMID1234)"
export DELTREE_NOTARY_PROFILE="deltree-notary-profile"

export DELTREE_APP_STORE_CONNECT_KEY_ID="ABC123DEFG"
export DELTREE_APP_STORE_CONNECT_ISSUER_ID="00000000-0000-0000-0000-000000000000"
export DELTREE_APP_STORE_CONNECT_API_KEY_FILE="$HOME/.config/deltree/private/AuthKey_ABC123DEFG.p8"

export DELTREE_SPARKLE_PUBLIC_ED_KEY="YOUR_SPARKLE_PUBLIC_ED25519_KEY"
export DELTREE_SPARKLE_FEED_URL="https://github.com/hazennik/DELTREE/releases/latest/download/appcast.xml"
# Optional if you generated Sparkle keys under a non-default Keychain account.
# export DELTREE_SPARKLE_ACCOUNT="deltree"
# Optional fallback if you choose a private key file instead of Sparkle Keychain storage.
# export DELTREE_SPARKLE_PRIVATE_KEY_FILE="$HOME/.config/deltree/private/sparkle_ed25519_private_key"

# Optional. If omitted, Scripts/release-local.sh uses the current git commit count.
# export DELTREE_BUILD_VERSION="42"
EOF
}

script_dir="${0:A:h}"
repo_root="${script_dir:h}"
env_file="${DELTREE_LOCAL_RELEASE_ENV:-$HOME/.config/deltree/release.env}"

while (($#)); do
  case "$1" in
    --env-file)
      shift
      env_file="${1:-}"
      ;;
    --print-template)
      print_template
      exit 0
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

if [[ -z "$env_file" ]]; then
  echo "--env-file requires a path." >&2
  exit 2
fi

if [[ ! -f "$env_file" ]]; then
  echo "Local release env file not found: $env_file" >&2
  echo "Create it with:" >&2
  echo "  mkdir -p ~/.config/deltree/private" >&2
  echo "  Scripts/setup-local-release-secrets.sh --print-template > ~/.config/deltree/release.env" >&2
  echo "  chmod 600 ~/.config/deltree/release.env" >&2
  exit 2
fi

set -a
source "$env_file"
set +a

required=(
  DELTREE_TEAM_ID
  DELTREE_DEVELOPER_ID_APPLICATION
  DELTREE_NOTARY_PROFILE
  DELTREE_APP_STORE_CONNECT_KEY_ID
  DELTREE_APP_STORE_CONNECT_ISSUER_ID
  DELTREE_APP_STORE_CONNECT_API_KEY_FILE
  DELTREE_SPARKLE_PUBLIC_ED_KEY
)

missing=()
for name in "${required[@]}"; do
  value="${(P)name:-}"
  if [[ -z "$value" ]]; then
    missing+=("$name")
  fi
done

if (( ${#missing[@]} )); then
  echo "Missing required local release setting(s): ${missing[*]}" >&2
  exit 2
fi

api_key_file="${DELTREE_APP_STORE_CONNECT_API_KEY_FILE:A}"
private_paths=("$api_key_file")
if [[ -n "${DELTREE_SPARKLE_PRIVATE_KEY_FILE:-}" ]]; then
  private_paths+=("${DELTREE_SPARKLE_PRIVATE_KEY_FILE:A}")
fi

for private_path in "${private_paths[@]}"; do
  case "$private_path" in
    "$repo_root"/*)
      echo "Private release files must live outside the repository: $private_path" >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$api_key_file" ]]; then
  echo "App Store Connect API key file not found: $api_key_file" >&2
  exit 2
fi

if [[ -n "${DELTREE_SPARKLE_PRIVATE_KEY_FILE:-}" && ! -f "${DELTREE_SPARKLE_PRIVATE_KEY_FILE:A}" ]]; then
  echo "Sparkle private key file not found: ${DELTREE_SPARKLE_PRIVATE_KEY_FILE:A}" >&2
  exit 2
fi

if ! security find-identity -v -p codesigning | grep -F -- "$DELTREE_DEVELOPER_ID_APPLICATION" >/dev/null; then
  echo "Developer ID signing identity is not installed in this Mac's keychain:" >&2
  echo "  $DELTREE_DEVELOPER_ID_APPLICATION" >&2
  exit 1
fi

notary_args=(
  "$DELTREE_NOTARY_PROFILE"
  --key "$api_key_file"
  --key-id "$DELTREE_APP_STORE_CONNECT_KEY_ID"
  --issuer "$DELTREE_APP_STORE_CONNECT_ISSUER_ID"
  --validate
)

if [[ -n "${DELTREE_NOTARY_KEYCHAIN:-}" ]]; then
  notary_args+=(--keychain "$DELTREE_NOTARY_KEYCHAIN")
fi

xcrun notarytool store-credentials "${notary_args[@]}"

echo "Local release credentials are configured for profile: $DELTREE_NOTARY_PROFILE"

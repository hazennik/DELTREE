#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/generate-homebrew-cask.sh --version VERSION --sha256 SHA256 [--output PATH] [--url URL]

Generates a Homebrew cask for the Homebrew-channel DELTREE artifact.
The URL must point at DELTREE-homebrew.zip, not the Developer ID Sparkle artifact.
EOF
}

version=""
sha256=""
output=""
url=""

while (($#)); do
  case "$1" in
    --version)
      shift
      version="${1:-}"
      ;;
    --sha256)
      shift
      sha256="${1:-}"
      ;;
    --output)
      shift
      output="${1:-}"
      ;;
    --url)
      shift
      url="${1:-}"
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

if [[ ! "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
  echo "--version must be a stable SemVer version like 1.0.0." >&2
  exit 2
fi

if [[ ! "$sha256" =~ '^[0-9a-f]{64}$' ]]; then
  echo "--sha256 must be a lowercase SHA-256 digest." >&2
  exit 2
fi

url="${url:-https://github.com/hazennik/DELTREE/releases/download/v${version}/DELTREE-homebrew.zip}"
if [[ "$url" != *"/DELTREE-homebrew.zip" ]]; then
  echo "Homebrew cask URL must end in DELTREE-homebrew.zip." >&2
  exit 1
fi

render_cask() {
  cat <<EOF
cask "deltree" do
  version "$version"
  sha256 "$sha256"

  url "$url"
  name "DELTREE"
  desc "Privacy-first macOS utility for safely managing Codex and Xcode storage"
  homepage "https://github.com/hazennik/DELTREE"

  depends_on macos: ">= :sonoma"

  app "DELTREE.app"

  zap trash: [
    "~/Library/Application Support/DELTREE",
    "~/Library/Preferences/com.Infrallabs.DELTREE.plist",
  ]
end
EOF
}

if [[ -n "$output" ]]; then
  mkdir -p "$(dirname "$output")"
  render_cask >"$output"
  echo "Created $output"
else
  render_cask
fi

#!/usr/bin/env zsh
set -euo pipefail

root_dir="${DELTREE_SECRET_CHECK_ROOT:-${0:A:h:h}}"
cd "$root_dir"

failures=0
sensitive_file_regex='(^|/)(\.env(\..*)?|[^/]+\.env|release\.env|local-release\.env|\.deltree-release\.env|AuthKey_[A-Za-z0-9]+\.p8|[^/]+\.(p8|p12|pem|key|cer|crt|der|certSigningRequest|mobileprovision|provisionprofile))$'
content_secret_regex='-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----|sk-proj-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|glpat-[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}'

report() {
  print -r -- "$1" >&2
  failures=$((failures + 1))
}

while IFS= read -r tracked_file; do
  case "$tracked_file" in
    *.env.example|*.env.sample) continue ;;
  esac
  if [[ "$tracked_file" =~ $sensitive_file_regex ]]; then
    report "Tracked sensitive file name: $tracked_file"
  fi
done < <(git ls-files)

while IFS= read -r -d '' local_file; do
  relative_path="${local_file#./}"
  case "$relative_path" in
    *.env.example|*.env.sample) continue ;;
  esac
  if [[ "$relative_path" =~ $sensitive_file_regex ]]; then
    report "Sensitive local file inside repo: $relative_path"
  fi
done < <(
  find . \
    \( -path './.git' -o -path './build' -o -path './.build' -o -path './.swiftpm' -o -path './DerivedData' \) -prune \
    -o -type f -print0
)

content_matches="$(
  git grep -n -I -E -e "$content_secret_regex" -- . \
    ':(exclude)Scripts/check-no-secrets.sh' || true
)"

if [[ -n "$content_matches" ]]; then
  report "Tracked file content looks like it may contain a private key or token:"
  print -r -- "$content_matches" >&2
fi

if ((failures > 0)); then
  printf 'Secret check failed with %d issue(s).\n' "$failures" >&2
  exit 1
fi

echo "Secret check passed."

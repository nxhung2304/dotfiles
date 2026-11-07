#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
active_zshrc_lines=$(grep -vE '^[[:space:]]*#' "$repo_dir/.zshrc")

while IFS= read -r formula; do
    formula_state=missing
    grep -qE "^brew \"$formula\"" "$repo_dir/Brewfile" && formula_state=listed
    check "Brewfile lists $formula used in .zshrc" "listed" "$formula_state"
done < <(grep -oE '\$HOMEBREW_PREFIX/opt/[A-Za-z0-9@._+-]+' <<<"$active_zshrc_lines" | sed 's|.*/opt/||' | sort -u)

check "no hardcoded Homebrew opt path in .zshrc" "0" \
    "$(grep -cE '(/usr/local|/opt/homebrew)/opt/' <<<"$active_zshrc_lines" || true)"
check "JAVA_HOME is left to mise" "0" "$(grep -cE 'export JAVA_HOME=' <<<"$active_zshrc_lines" || true)"

finish_tests

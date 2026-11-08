#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

mkdir -p "$work_dir/stub-bin" "$work_dir/no-mise-bin"
printf '%s\n' '#!/usr/bin/env bash' \
    'echo "mkdir -p \"\$HOME/.local/bin\" && touch \"\$HOME/.local/bin/mise\" && chmod +x \"\$HOME/.local/bin/mise\""' \
    >"$work_dir/stub-bin/curl"
chmod +x "$work_dir/stub-bin/curl"

run_binary_install() {
    local home_dir=$1 answer=$2 tool_dir=$3
    (
        export HOME=$home_dir
        export PATH="$tool_dir:$work_dir/stub-bin:/usr/bin:/bin"
        source "$repo_dir/scripts/install/common.sh"
        source "$repo_dir/scripts/install/mise.sh"
        printf '%s\n' "$answer" | install_mise_binary >/dev/null 2>&1
    )
}

present_home="$work_dir/present-home"
mkdir -p "$present_home/bin"
printf '#!/bin/sh\n' >"$present_home/bin/mise"
chmod +x "$present_home/bin/mise"

exit_code=0
run_binary_install "$present_home" "" "$present_home/bin" || exit_code=$?
check "existing mise is used without asking" "0" "$exit_code"
check "existing mise is not reinstalled" "missing" "$(describe_path "$present_home/.local/bin/mise")"

declined_home="$work_dir/declined-home"
mkdir -p "$declined_home"

exit_code=0
run_binary_install "$declined_home" "n" "$work_dir/no-mise-bin" || exit_code=$?
check "declining the install stops the step" "1" "$exit_code"

accepted_home="$work_dir/accepted-home"
mkdir -p "$accepted_home"

exit_code=0
run_binary_install "$accepted_home" "y" "$work_dir/no-mise-bin" || exit_code=$?
check "accepting installs mise" "0" "$exit_code"
check "mise lands in ~/.local/bin" "file" "$(describe_path "$accepted_home/.local/bin/mise")"

finish_tests

#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
dotfiles_dir="$work_dir/dotfiles"
copy_repo_to "$dotfiles_dir"
mkdir -p "$work_dir/home"

run_installer() {
    HOME="$work_dir/home" bash "$dotfiles_dir/install.sh" "$@" >"$work_dir/output" 2>&1
}

run_installer --help
check "help lists the stow step" "1" "$(grep -c 'Steps: .*stow' "$work_dir/output")"

exit_code=0
run_installer stow no-such-step || exit_code=$?
check "unknown step fails" "1" "$exit_code"
check "unknown step is named in the error" "1" "$(grep -c 'Unknown step: no-such-step' "$work_dir/output")"
check "nothing runs when a step is unknown" "0" "$(grep -c 'SYMLINK' "$work_dir/output")"

exit_code=0
printf 'n\n' | run_installer stow || exit_code=$?
check "single step succeeds" "0" "$exit_code"
check "single step runs only that step" "1" "$(grep -c 'SYMLINK' "$work_dir/output")"
check "single step skips the final summary" "0" "$(grep -c 'INSTALLATION COMPLETE' "$work_dir/output")"

finish_tests

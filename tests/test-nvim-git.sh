#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
plugins_dir="$work_dir/plugins"
nvim_timeout_seconds=120

if ! command -v nvim &>/dev/null; then
    echo "  SKIP nvim is not installed"

    exit 0
fi

clone_plugin() {
    local name=$1 url=$2 commit
    commit=$(jq -r --arg name "$name" '.[$name].commit // empty' "$repo_dir/.config/nvim/lazy-lock.json")
    git clone -q --filter=blob:none "$url" "$plugins_dir/$name"
    if [[ -n $commit ]]; then
        git -C "$plugins_dir/$name" checkout -q "$commit"
    fi
}

clone_plugin neogit https://github.com/NeogitOrg/neogit
clone_plugin diffbandit.nvim https://github.com/CoreyKaylor/diffbandit.nvim

new_repo() {
    local dir=$1 branch=$2
    mkdir -p "$dir"
    git -C "$dir" init -q -b "$branch"
    git -C "$dir" config user.email test@example.com
    git -C "$dir" config user.name test
}

commit_line() {
    local dir=$1 line=$2
    echo "$line" >>"$dir/f"
    git -C "$dir" add f
    git -C "$dir" commit -qm "$line"
}

run_case() {
    local test_case=$1 dir=$2
    echo "--- $test_case"
    (cd "$dir" && TEST_CASE=$test_case TEST_PLUGINS_DIR=$plugins_dir TEST_REPO_DIR=$repo_dir \
        timeout "$nvim_timeout_seconds" nvim --headless -u NONE -i NONE -l "$repo_dir/tests/nvim/git_spec.lua")
}

failed=0

status_repo="$work_dir/status"
new_repo "$status_repo" master
printf 'a\nb\n' >"$status_repo/hello.txt"
git -C "$status_repo" add hello.txt
git -C "$status_repo" commit -qm first
commit_line "$status_repo" staged_base
echo "staged change" >>"$status_repo/f"
git -C "$status_repo" add f
echo "changed" >>"$status_repo/hello.txt"
run_case neogit_popup "$status_repo" || failed=1

branch_repo="$work_dir/branch"
new_repo "$branch_repo" main
commit_line "$branch_repo" base
git -C "$branch_repo" checkout -qb develop
commit_line "$branch_repo" develop_before_branch
git -C "$branch_repo" checkout -qb feature
commit_line "$branch_repo" feature_work
git -C "$branch_repo" checkout -q develop
commit_line "$branch_repo" develop_after_branch
git -C "$branch_repo" checkout -q feature
run_case review_branch "$branch_repo" || failed=1

no_base_repo="$work_dir/no-base"
new_repo "$no_base_repo" trunk
commit_line "$no_base_repo" only
run_case no_base_branch "$no_base_repo" || failed=1

conflict_repo="$work_dir/conflict"
new_repo "$conflict_repo" main
printf 'a\nb\nc\n' >"$conflict_repo/f"
git -C "$conflict_repo" add f
git -C "$conflict_repo" commit -qm base
git -C "$conflict_repo" checkout -qb other
printf 'a\nTHEIRS\nc\n' >"$conflict_repo/f"
git -C "$conflict_repo" commit -qam theirs
git -C "$conflict_repo" checkout -q main
printf 'a\nOURS\nc\n' >"$conflict_repo/f"
git -C "$conflict_repo" commit -qam ours
if git -C "$conflict_repo" merge -q other >/dev/null 2>&1; then
    echo "  FAIL test setup: the merge should have stopped on a conflict"

    exit 1
fi
run_case merge_conflict "$conflict_repo" || failed=1

exit "$failed"

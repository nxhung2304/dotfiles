#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
home_dir="$work_dir/home"
rights_dir="$home_dir/Dev/rights"
hook_script="$repo_dir/.claude/hooks/guard_remote_write.py"
whitelisted_hook="$work_dir/guard_whitelisted.py"
allowed_exit_code=0
blocked_exit_code=2

create_repo() {
    local repo_path=$1
    git init -q -b main "$repo_path"
    git -C "$repo_path" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m init
    git -C "$repo_path" update-ref refs/remotes/origin/main HEAD
    git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
    git -C "$repo_path" checkout -q -b feature/x
}

allowed_repo="$rights_dir/allowed"
blocked_repo="$rights_dir/blocked"
personal_repo="$home_dir/Dev/personal/mine"
create_repo "$allowed_repo"
create_repo "$blocked_repo"
create_repo "$personal_repo"
sed 's/^WHITELISTED_PROJECTS = \[\]/WHITELISTED_PROJECTS = ["allowed"]/' "$hook_script" >"$whitelisted_hook"

bash_call() {
    local cwd=$1
    local command=$2
    jq -cn --arg cwd "$cwd" --arg command "$command" '{tool_name: "Bash", cwd: $cwd, tool_input: {command: $command}}'
}

github_call() {
    local action=$1
    local tool_input=$2
    jq -cn --arg action "$action" --argjson input "$tool_input" \
        '{tool_name: ("mcp__github__" + $action), cwd: "/tmp", tool_input: $input}'
}

exit_code_of() {
    local hook=$1
    local hook_input=$2
    local exit_code=0
    HOME="$home_dir" python3 -I "$hook" <<<"$hook_input" 2>/dev/null || exit_code=$?
    echo "$exit_code"
}

check "non-whitelisted push is blocked" "$blocked_exit_code" \
    "$(exit_code_of "$hook_script" "$(bash_call "$blocked_repo" "git push -u origin feature/x")")"
check "non-whitelisted PR is blocked" "$blocked_exit_code" \
    "$(exit_code_of "$hook_script" "$(github_call create_pull_request '{"repo":"blocked"}')")"
check "reading a rights repo is allowed" "$allowed_exit_code" \
    "$(exit_code_of "$hook_script" "$(bash_call "$blocked_repo" "gh issue list")")"
check "personal repo push to main is allowed" "$allowed_exit_code" \
    "$(exit_code_of "$hook_script" "$(bash_call "$personal_repo" "git push origin main")")"

check "whitelisted feature push is allowed" "$allowed_exit_code" \
    "$(exit_code_of "$whitelisted_hook" "$(bash_call "$allowed_repo" "git push -u origin feature/x")")"
check "whitelisted PR is allowed" "$allowed_exit_code" \
    "$(exit_code_of "$whitelisted_hook" "$(bash_call "$allowed_repo" "gh pr create --fill")")"
check "whitelisted push to main is blocked" "$blocked_exit_code" \
    "$(exit_code_of "$whitelisted_hook" "$(bash_call "$allowed_repo" "git push origin HEAD:main")")"
check "push to main via cd is blocked" "$blocked_exit_code" \
    "$(exit_code_of "$whitelisted_hook" "$(bash_call /tmp "cd $allowed_repo && git push origin main")")"
check "push of all branches is blocked" "$blocked_exit_code" \
    "$(exit_code_of "$whitelisted_hook" "$(bash_call "$allowed_repo" "git push --all")")"
check "merge is blocked" "$blocked_exit_code" \
    "$(exit_code_of "$whitelisted_hook" "$(bash_call "$allowed_repo" "gh pr merge 3 --squash")")"
check "file push to main through GitHub is blocked" "$blocked_exit_code" \
    "$(exit_code_of "$whitelisted_hook" "$(github_call push_files '{"repo":"allowed","branch":"main"}')")"
check "unreadable input is blocked" "$blocked_exit_code" "$(exit_code_of "$hook_script" "not json")"

git -C "$allowed_repo" checkout -q main
check "bare push while on main is blocked" "$blocked_exit_code" \
    "$(exit_code_of "$whitelisted_hook" "$(bash_call "$allowed_repo" "git push")")"

finish_tests

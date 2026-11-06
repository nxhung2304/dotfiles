#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin" "$work_dir/home/.local/bin/scripts"
repo_url="https://github.com/org/repo"

cat >"$work_dir/bin/herdr" <<STUB
#!/usr/bin/env bash
echo '{"result":{"pane":{"cwd":"$work_dir"}}}'
STUB
cat >"$work_dir/bin/gh" <<STUB
#!/usr/bin/env bash
account=\$(cat "$work_dir/account")
case "\$1 \$2" in
    "repo view")
        [[ \$account == work ]] || exit 1
        echo "$repo_url"
        ;;
    "pr view")
        [[ -f "$work_dir/has-pr" && \$account == work ]] || exit 1
        echo "$repo_url/pull/7"
        ;;
    "auth status") printf 'Logged in to github.com account personal\nLogged in to github.com account work\n' >&2 ;;
    "auth switch") echo "\$4" >"$work_dir/account" ;;
esac
STUB
cat >"$work_dir/bin/fzf" <<STUB
#!/usr/bin/env bash
[[ -f "$work_dir/fzf-cancel" ]] && exit 130
grep -x work
STUB
cat >"$work_dir/home/.local/bin/scripts/open-or-focus-tab" <<STUB
#!/usr/bin/env bash
echo "\$1" >"$work_dir/opened"
STUB
chmod +x "$work_dir"/bin/* "$work_dir/home/.local/bin/scripts/open-or-focus-tab"

open_page() {
    local account=$1 page=$2 mode=${3:-tty}
    echo "$account" >"$work_dir/account"
    rm -f "$work_dir/opened"
    local script_path="$repo_dir/scripts/herdr/open-git-page"
    local command="PATH='$work_dir/bin:$PATH' HOME='$work_dir/home' bash '$script_path' $page"
    local exit_code=0
    if [[ $mode == tty ]]; then
        script -qec "$command" /dev/null >/dev/null 2>&1 || exit_code=$?
    else
        bash -c "$command" </dev/null >/dev/null 2>&1 || exit_code=$?
    fi
    echo "$exit_code" >"$work_dir/exit-code"

    cat "$work_dir/opened" 2>/dev/null || echo "nothing"
}

touch "$work_dir/has-pr"
check "current PR opens" "$repo_url/pull/7" "$(open_page work current)"
rm "$work_dir/has-pr"
check "no PR falls back to the PR list" "$repo_url/pulls" "$(open_page work current)"
check "repo page" "$repo_url" "$(open_page work repo)"
check "issues page" "$repo_url/issues" "$(open_page work issues)"
check "wrong account switches and opens" "$repo_url/pulls" "$(open_page personal pulls)"
check "account was switched" "work" "$(cat "$work_dir/account")"
check "wrong account without terminal opens nothing" "nothing" "$(open_page personal pulls no-tty)"
check "wrong account without terminal fails" "1" "$(cat "$work_dir/exit-code")"
touch "$work_dir/fzf-cancel"
check "cancelled account picker opens nothing" "nothing" "$(open_page personal pulls)"
check "cancelled account picker fails" "1" "$(cat "$work_dir/exit-code")"

finish_tests

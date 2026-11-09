#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
work_dir=$(cd "$work_dir" && pwd -P)

stub_bin="$work_dir/bin"
mkdir -p "$stub_bin"

cat >"$stub_bin/tmux" <<STUB
#!/usr/bin/env bash
pwd -P >"$work_dir/tmux_cwd"
echo "\$*" >"$work_dir/tmux_args"
STUB

cat >"$stub_bin/herdr" <<STUB
#!/usr/bin/env bash
echo "\$*" >"$work_dir/herdr_args"
echo "{\"result\":{\"pane\":{\"cwd\":\"\$STUB_PANE_CWD\"}}}"
STUB

chmod +x "$stub_bin/tmux" "$stub_bin/herdr"

make_git_repo() {
    local directory=$1
    mkdir -p "$directory"
    git -C "$directory" init -q
}

open_from_pane() {
    local directory=$1
    STUB_PANE_CWD=$directory HERDR_ACTIVE_PANE_ID=w1:p1 PATH="$stub_bin:$PATH" \
        "$repo_dir/scripts/herdr/floating-terminal"
}

session_name_from_pane() {
    local directory=$1
    open_from_pane "$directory"
    awk '{print $NF}' "$work_dir/tmux_args"
}

name_without_hash() {
    local session_name=$1
    echo "${session_name%-*}"
}

are_different() {
    local first=$1
    local second=$2
    if [[ $first != "$second" ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

project_a="$work_dir/one/project-a"
project_a_subdir="$project_a/lib/deep"
project_b="$work_dir/one/project-b"
same_name_elsewhere="$work_dir/two/project-a"
dotted_project="$work_dir/one/my.app"
plain_dir="$work_dir/one/not-a-repo"

make_git_repo "$project_a"
make_git_repo "$project_b"
make_git_repo "$same_name_elsewhere"
make_git_repo "$dotted_project"
mkdir -p "$project_a_subdir" "$plain_dir"

echo "test-floating-terminal"

session_a=$(session_name_from_pane "$project_a")
expected_args="-L herdr-floating -f $repo_dir/scripts/herdr/floating-terminal.tmux.conf new-session -A -s $session_a"
check "attaches or creates the session on the dedicated socket" "$expected_args" "$(cat "$work_dir/tmux_args")"
check "asks herdr about the focused pane" "pane get w1:p1" "$(cat "$work_dir/herdr_args")"
check "starts in the focused pane directory" "$project_a" "$(cat "$work_dir/tmux_cwd")"
check "session name starts with the project name" "project-a" "$(name_without_hash "$session_a")"

session_a_subdir=$(session_name_from_pane "$project_a_subdir")
check "subdirectory shares the project session" "$session_a" "$session_a_subdir"
check "subdirectory session still starts in the pane directory" "$project_a_subdir" "$(cat "$work_dir/tmux_cwd")"

session_b=$(session_name_from_pane "$project_b")
same_name_session=$(session_name_from_pane "$same_name_elsewhere")
check "another project gets its own session" "yes" "$(are_different "$session_a" "$session_b")"
check "same folder name in another path gets its own session" "yes" "$(are_different "$session_a" "$same_name_session")"

dotted_session=$(session_name_from_pane "$dotted_project")
check "dots are removed from the session name" "my_app" "$(name_without_hash "$dotted_session")"

plain_session=$(session_name_from_pane "$plain_dir")
check "directory outside git uses its own name" "not-a-repo" "$(name_without_hash "$plain_session")"

(
    cd "$project_b"
    unset HERDR_ACTIVE_PANE_ID
    PATH="$stub_bin:$PATH" "$repo_dir/scripts/herdr/floating-terminal"
)
check "uses the current directory without a focused pane" "$project_b" "$(cat "$work_dir/tmux_cwd")"
session_without_pane=$(awk '{print $NF}' "$work_dir/tmux_args")
check "uses the current project session without a focused pane" "$session_b" "$session_without_pane"

finish_tests

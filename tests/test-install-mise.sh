#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

run_warning() {
    (
        export HOME=$1
        source "$repo_dir/scripts/install/common.sh"
        source "$repo_dir/scripts/install/mise.sh"
        warn_about_versions_linked_to_asdf
    )
}

linked_home="$work_dir/linked-home"
mkdir -p "$linked_home/.asdf/installs/ruby/3.3.11" "$linked_home/.local/share/mise/installs/ruby"
mkdir -p "$linked_home/.local/share/mise/installs/node/22.22.2"
ln -s "$linked_home/.asdf/installs/ruby/3.3.11" "$linked_home/.local/share/mise/installs/ruby/3.3.11"
warning=$(run_warning "$linked_home")
check "warns about a version linked into ~/.asdf" "1" "$(grep -c 'ruby/3.3.11' <<<"$warning")"
check "does not list versions mise installed itself" "0" "$(grep -c 'node/22.22.2' <<<"$warning")"

clean_home="$work_dir/clean-home"
mkdir -p "$clean_home/.local/share/mise/installs/node/22.22.2"
check "no warning when nothing links into ~/.asdf" "" "$(run_warning "$clean_home")"
check "no warning when mise has no installs" "" "$(run_warning "$work_dir/empty-home")"

finish_tests

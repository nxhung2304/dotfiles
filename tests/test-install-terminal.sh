#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin"

cat >"$work_dir/bin/brew" <<EOF
#!/usr/bin/env bash
case "\$1" in
    list) [ -f "$work_dir/tmux-installed" ] ;;
    uninstall) rm -f "$work_dir/tmux-installed" ;;
esac
EOF
chmod +x "$work_dir/bin/brew"

remove_leftovers() {
    local home_dir=$1 answers=$2
    (
        export HOME=$home_dir PATH="$work_dir/bin:$PATH"
        source "$repo_dir/scripts/install/common.sh"
        source "$repo_dir/scripts/install/terminal.sh"
        printf '%b' "$answers" | remove_tmux_leftovers >/dev/null 2>&1
    )
}

home_dir="$work_dir/home"
mkdir -p "$home_dir/.config" "$home_dir/.local/bin/scripts" "$home_dir/.tmux/plugins"
ln -s /nowhere "$home_dir/.config/tmux"
ln -s /nowhere "$home_dir/.local/bin/scripts/tmux-sessionizer"
touch "$work_dir/tmux-installed"

remove_leftovers "$home_dir" 'y\ny\n'
check "old tmux config link removed" "missing" "$(describe_path "$home_dir/.config/tmux")"
check "old sessionizer link removed" "missing" "$(describe_path "$home_dir/.local/bin/scripts/tmux-sessionizer")"
check "tmux plugins folder removed after yes" "missing" "$(describe_path "$home_dir/.tmux")"
check "tmux uninstalled after yes" "missing" "$(describe_path "$work_dir/tmux-installed")"

kept_home="$work_dir/kept-home"
mkdir -p "$kept_home/.config/tmux" "$kept_home/.tmux"
touch "$work_dir/tmux-installed"
remove_leftovers "$kept_home" 'n\nn\n'
check "real tmux config folder kept" "dir" "$(describe_path "$kept_home/.config/tmux")"
check "tmux plugins folder kept after no" "dir" "$(describe_path "$kept_home/.tmux")"
check "tmux kept after no" "file" "$(describe_path "$work_dir/tmux-installed")"

finish_tests

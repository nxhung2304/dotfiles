#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
dotfiles_dir="$work_dir/dotfiles"
copy_repo_to "$dotfiles_dir"
touch "$dotfiles_dir/scripts/tmux-sessionizer"

run_stow_step() {
    local home_dir=$1
    (
        export HOME=$home_dir DOTFILES_DIR=$dotfiles_dir
        cd "$dotfiles_dir"
        source scripts/install/common.sh
        source scripts/install/stow.sh
        printf 'n\n' | install_stow >/dev/null 2>&1
    )
}

list_home_clutter() {
    find "$1" -mindepth 1 -maxdepth 1 ! -name '.*' -exec basename {} \; | sort | tr '\n' ' '
}

count_backups() {
    find "$1/.dotfiles-backup" \( -type f -o -type l \) 2>/dev/null | wc -l | tr -d ' '
}

fresh_home="$work_dir/fresh-home"
mkdir -p "$fresh_home"
run_stow_step "$fresh_home"
check "fresh home: config folder linked" "link" "$(describe_path "$fresh_home/.config/herdr")"
check "fresh home: claude settings linked" "link" "$(describe_path "$fresh_home/.claude/settings.json")"
check "fresh home: scripts linked" "link" "$(describe_path "$fresh_home/.local/bin/scripts/open-or-focus-tab")"
check "fresh home: no stray links in home" "" "$(list_home_clutter "$fresh_home")"

old_home="$work_dir/old-home"
mkdir -p "$old_home/.claude/hooks" "$old_home/.claude/projects/demo"
ln -s "$dotfiles_dir/.config" "$old_home/.config"
ln -s "$dotfiles_dir/.claude/settings.json" "$old_home/.claude/settings.json"
ln -s "$dotfiles_dir/.claude/hooks/ai_track.py" "$old_home/.claude/hooks/ai_track.py"
echo "user data" > "$old_home/.claude/projects/demo/notes"
echo "user statusline" > "$old_home/.claude/statusline-command.sh"
(cd "$dotfiles_dir" && stow --target="$old_home" scripts)
rm "$dotfiles_dir/scripts/tmux-sessionizer"

run_stow_step "$old_home"
check "old home: whole ~/.config link kept" "$dotfiles_dir/.config" "$(readlink "$old_home/.config")"
check "old home: absolute link replaced by relative link" "../../dotfiles/.claude/settings.json" \
    "$(readlink "$old_home/.claude/settings.json")"
check "old home: hook link replaced" "../../../dotfiles/.claude/hooks/ai_track.py" \
    "$(readlink "$old_home/.claude/hooks/ai_track.py")"
check "old home: stray links removed from home" "" "$(list_home_clutter "$old_home")"
check "old home: real user file backed up" "user statusline" \
    "$(cat "$old_home"/.dotfiles-backup/*/.claude/statusline-command.sh)"
check "old home: statusline script now linked" "link" "$(describe_path "$old_home/.claude/statusline-command.sh")"
check "old home: other claude data untouched" "user data" "$(cat "$old_home/.claude/projects/demo/notes")"

run_stow_step "$old_home"
check "second run: nothing new backed up" "1" "$(count_backups "$old_home")"
check "second run: links still in place" "link" "$(describe_path "$old_home/.claude/settings.json")"

finish_tests

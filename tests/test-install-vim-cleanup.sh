#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

run_cleanup() {
    (
        export HOME=$1
        DOTFILES_DIR=$2
        source "$repo_dir/scripts/install/common.sh"
        source "$repo_dir/scripts/install/vim-cleanup.sh"
        install_vim_cleanup
    ) >/dev/null
}

old_home="$work_dir/old-home"
mkdir -p "$old_home/.vim/autoload" "$old_home/.vim/plugged/vim-surround"
touch "$old_home/.vim/autoload/plug.vim"
ln -s "$work_dir/dotfiles/.vimrc" "$old_home/.vimrc"
run_cleanup "$old_home" "$work_dir/dotfiles"
check "removes the ~/.vimrc link this repo created" "missing" "$(describe_path "$old_home/.vimrc")"
check "removes ~/.vim when it held only vim-plug" "missing" "$(describe_path "$old_home/.vim")"

own_home="$work_dir/own-home"
mkdir -p "$own_home/.vim/autoload" "$own_home/.vim/undo"
touch "$own_home/.vim/autoload/plug.vim" "$own_home/.vimrc"
run_cleanup "$own_home" "$work_dir/dotfiles"
check "keeps a ~/.vimrc the user wrote" "file" "$(describe_path "$own_home/.vimrc")"
check "keeps other files in ~/.vim" "dir" "$(describe_path "$own_home/.vim/undo")"
check "still removes vim-plug next to them" "missing" "$(describe_path "$own_home/.vim/autoload/plug.vim")"

clean_home="$work_dir/clean-home"
mkdir -p "$clean_home"
exit_code=0
run_cleanup "$clean_home" "$work_dir/dotfiles" || exit_code=$?
check "succeeds when there is nothing to clean" "0" "$exit_code"

finish_tests

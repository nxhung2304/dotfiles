#!/usr/bin/env bash
# Remove the Vim setup left by older versions of this repo

remove_vimrc_link() {
    local vimrc="$HOME/.vimrc"
    if [ -L "$vimrc" ] && [[ $(readlink "$vimrc") == "$DOTFILES_DIR/.vimrc" ]]; then
        rm "$vimrc"
        log_success "Removed ~/.vimrc link"
    elif [ -e "$vimrc" ] || [ -L "$vimrc" ]; then
        log_info "Kept ~/.vimrc: it is not the link this repo created"
    fi
}

remove_vim_plug() {
    local vim_dir="$HOME/.vim"
    [ -e "$vim_dir/plugged" ] || [ -e "$vim_dir/autoload/plug.vim" ] || return 0

    rm -rf "$vim_dir/plugged" "$vim_dir/autoload/plug.vim"
    rmdir "$vim_dir/autoload" "$vim_dir" 2>/dev/null || true
    log_success "Removed vim-plug and its plugins"
}

install_vim_cleanup() {
    log_header "VIM CLEANUP"

    remove_vimrc_link
    remove_vim_plug
}

#!/usr/bin/env bash
# Setup symlinks with stow

STOW_PACKAGES=(".config" ".claude" "scripts")

stow_target_for() {
    case $1 in
        scripts) echo "$HOME/.local/bin/scripts" ;;
        *) echo "$HOME/$1" ;;
    esac
}

resolve_existing_path() {
    local path=$1
    if [ -d "$path" ]; then
        (cd "$path" && pwd -P)
    elif [ -e "$path" ]; then
        local real_parent_dir
        real_parent_dir=$(cd "$(dirname "$path")" && pwd -P)
        echo "$real_parent_dir/$(basename "$path")"
    fi
}

resolve_link_destination() {
    local link=$1 destination
    destination=$(readlink "$link")
    if [[ $destination != /* ]]; then
        destination="$(dirname "$link")/$destination"
    fi

    resolve_existing_path "$destination"
}

is_inside_dotfiles() {
    local real_path=$1 real_dotfiles_dir
    real_dotfiles_dir=$(resolve_existing_path "$DOTFILES_DIR")
    case $real_path in
        "$real_dotfiles_dir" | "$real_dotfiles_dir"/*) return 0 ;;
        *) return 1 ;;
    esac
}

back_up_target() {
    local target=$1 backup
    backup="$BACKUP_DIR${target#"$HOME"}"
    mkdir -p "$(dirname "$backup")"
    mv "$target" "$backup"
    log_info "Backed up $target -> $backup"
}

clear_link() {
    local package_entry=$1 target=$2
    if [[ $(resolve_link_destination "$target") == "$(resolve_existing_path "$package_entry")" ]]; then
        rm "$target"

        return
    fi

    back_up_target "$target"
}

clear_way_for() {
    local package_entry=$1 target=$2
    local is_dir_on_both_sides=false
    if [ -d "$target" ] && [ -d "$package_entry" ]; then
        is_dir_on_both_sides=true
    fi

    if [ -L "$target" ]; then
        clear_link "$package_entry" "$target"
    elif $is_dir_on_both_sides; then
        clear_way_inside_dir "$package_entry" "$target"
    elif [ -e "$target" ]; then
        back_up_target "$target"
    fi
}

clear_way_inside_dir() {
    local package_dir=$1 target_dir=$2
    if is_inside_dotfiles "$(resolve_existing_path "$target_dir")"; then
        return
    fi

    local entry
    while IFS= read -r -d '' entry; do
        clear_way_for "$entry" "$target_dir/$(basename "$entry")"
    done < <(find "$package_dir" -mindepth 1 -maxdepth 1 -print0)
}

stow_package() {
    local package=$1 target
    target=$(stow_target_for "$package")
    mkdir -p "$target"
    if ! stow --delete --target="$HOME" "$package" &>/dev/null; then
        log_info "Could not remove old $package links from $HOME, check them by hand"
    fi

    if [[ $(resolve_existing_path "$target") == "$(resolve_existing_path "$DOTFILES_DIR/$package")" ]]; then
        log_success "$target already points to the repo"

        return
    fi

    clear_way_inside_dir "$DOTFILES_DIR/$package" "$target"
    stow --restow --target="$target" --verbose "$package" 2>&1 | tee "stow-${package#.}.log"
}

install_stow() {
    log_header "SYMLINK"

    if ask "Create backup of old config before stow?"; then
        BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        echo "📦 Backup location: $BACKUP_DIR"
        for path in ~/.config/nvim ~/.config/karabiner ~/.config/wezterm ~/.zshrc ~/.gitconfig ~/.vimrc; do
            [ -e "$path" ] && [ ! -L "$path" ] && cp -R "$path" "$BACKUP_DIR/"
        done
    fi
    BACKUP_DIR=${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}

    command -v stow &>/dev/null || brew install stow

    echo "🔗 Creating symlinks with stow..."
    local package
    for package in "${STOW_PACKAGES[@]}"; do
        if [ -d "$package" ]; then
            stow_package "$package"
        fi
    done

    log_success "Symlinks created"
}

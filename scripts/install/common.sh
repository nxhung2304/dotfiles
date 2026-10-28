#!/usr/bin/env bash
# Common functions for install modules

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ask() {
    printf "${YELLOW}❓ $1 (y/N): ${NC}"
    read -r ans
    [[ $ans =~ ^[Yy]$ ]]
}

backup_path() {
    local target="$1"
    local backup_dir="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mkdir -p "$backup_dir"
        mv "$target" "$backup_dir/"
        log_info "Backed up $target -> $backup_dir"
    fi
}

link_path() {
    local source="$1"
    local target="$2"
    if [ "$(cd "$(dirname "$target")" && pwd -P)/$(basename "$target")" = "$(cd "$(dirname "$source")" && pwd -P)/$(basename "$source")" ]; then
        return
    fi
    if [ -L "$target" ]; then
        rm "$target"
    else
        backup_path "$target"
    fi
    ln -s "$source" "$target"
}

log_header() {
    echo ""
    echo "====================== $1 ======================"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo "ℹ️  $1"
}

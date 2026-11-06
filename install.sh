#!/usr/bin/env bash
# =============================================
# Dotfiles Installer - nxhung2304 (macOS)
# Modular installer with optional components
# =============================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

echo "🚀 Starting dotfiles installation for nxhung2304..."

# Source common functions and modules
source scripts/install/common.sh
source scripts/install/editors.sh
source scripts/install/homebrew.sh
source scripts/install/brewfile.sh
source scripts/install/asdf.sh
source scripts/install/mobile.sh
source scripts/install/database.sh
source scripts/install/stow.sh
source scripts/install/git.sh
source scripts/install/shell.sh
source scripts/install/terminal.sh
source scripts/install/ai.sh
source scripts/install/vim.sh

# ====================== INSTALLATION FLOW ======================
INSTALL_STEPS=(editors homebrew brewfile asdf mobile database stow git_filters shell terminal ai vim)

print_usage() {
    echo "Usage: ./install.sh [step...]"
    echo "Runs every step when no step is given."
    echo "Steps: ${INSTALL_STEPS[*]}"
}

is_known_step() {
    [[ " ${INSTALL_STEPS[*]} " == *" $1 "* ]]
}

run_steps() {
    local step
    for step in "$@"; do
        "install_$step"
    done
}

case ${1:-} in
    -h | --help)
        print_usage

        exit 0
        ;;
esac

for requested_step in "$@"; do
    if ! is_known_step "$requested_step"; then
        log_error "Unknown step: $requested_step"
        print_usage

        exit 1
    fi
done

if [[ $# -gt 0 ]]; then
    run_steps "$@"

    exit 0
fi

run_steps "${INSTALL_STEPS[@]}"

# ====================== FINAL ======================
log_header "INSTALLATION COMPLETE"
echo -e "${GREEN}✅ Dotfiles installation finished!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. source ~/.zshrc"
echo "2. Open Karabiner-Elements → Enable"
echo "3. Neovim → :Lazy sync (installs plugins & language servers)"
echo "4. direnv allow . (if using .envrc files)"
echo ""
echo "Happy coding! 🔥"

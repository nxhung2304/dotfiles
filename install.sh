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
install_editors
install_homebrew
install_brewfile
install_asdf
install_mobile
install_database
install_stow
install_git_filters
install_shell
install_terminal
install_ai
install_vim

# ====================== FINAL ======================
log_header "INSTALLATION COMPLETE"
echo -e "${GREEN}✅ Dotfiles installation finished!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. source ~/.zshrc"
echo "2. Open Karabiner-Elements → Enable"
echo "3. Neovim → :Lazy sync (installs plugins & language servers)"
echo "4. tmux → Prefix + I (installs TPM plugins)"
echo "5. direnv allow . (if using .envrc files)"
echo ""
echo "Happy coding! 🔥"

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing terminal, editor, and development environment configurations. The repository uses symbolic linking to manage dotfiles from a centralized location.

## Setup Commands

- **Initial setup (full installation)**: `./install.sh` - Sets up Oh My Zsh, installs dependencies, creates symlinks
- **Manage dotfiles**: `./script.sh` - Creates symlinks for existing dotfiles to this repository
- **Make scripts executable**: `chmod +x script.sh` or `chmod +x install.sh`

## Architecture and Structure

### Configuration Management Strategy
- **Dotfiles**: Stored in repository root (`.zshrc`, `.gitconfig`, etc.)
- **App configs**: Organized in `.config/` directory by application
- **Scripts**: Located in `scripts/` directory
- **Symlink approach**: Files are symlinked from home directory to repository for centralized management

### Key Configuration Files

#### Neovim (`~/.config/nvim/`)
- **Entry point**: `init.lua` - Handles different environments (shadowvim, vscode, standard)
- **Core modules**: `lua/user/core/` - Contains options, keymaps, autocmds, custom commands
- **Plugin management**: Uses Lazy.nvim plugin manager
- **Environment-specific configs**: Separate plugin configs for Xcode (shadowvim), VS Code, and standard Neovim
- **Plugin structure**: `lua/user/plugins/` - Individual plugin configurations

#### Terminal Setup
- **Tmux**: Configuration split across multiple files in `.config/tmux/`:
  - `tmux.conf` - Main config file that sources other components
  - `tmux-options.conf` - Tmux options
  - `themes/gruvbox.conf` - Theme configuration
  - `tmux-keys.conf` - Key bindings
  - `tmux-plugins.conf` - Plugin configuration
- **Wezterm**: Modular Lua configuration in `.config/wezterm/`:
  - `wezterm.lua` - Main config file
  - Separate modules for `keys`, `fonts`, and `appearance`

#### Shell Configuration
- **Zsh**: Uses Oh My Zsh framework with custom aliases and environment variables
- **Plugins**: zsh-autosuggestions, zsh-syntax-highlighting, z (jump)
- **Theme**: robbyrussell
- **Custom aliases**: Docker commands, navigation shortcuts, editor shortcuts

### Development Environment Dependencies
- **Required**: nvim 0.11+, tmux, wezterm
- **Package managers**: asdf (runtime version management), brew (macOS)
- **Runtime support**: Ruby, Node.js via asdf plugins
- **Tools**: direnv for environment management

### Script Utilities
- **tmux-sessionizer**: Custom tmux session management script in `scripts/`
- **Dotfile management**: Two approaches via `install.sh` (full setup) and `script.sh` (symlink existing)

## Environment Configuration
- Copy `.env.sample` to `~/.env` for environment-specific variables
- Asdf integration for managing Ruby, Node.js versions
- Docker command aliases for common operations
- Flutter development path configured
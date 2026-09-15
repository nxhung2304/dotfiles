# dotfiles

Personal macOS development environment configuration managed via GNU Stow.

## Quick Setup

```bash
chmod +x install.sh
./install.sh
```

## What's Included

### Editors
| Tool | Config path | Description |
|------|-------------|-------------|
| Neovim | `.config/nvim/` | Primary editor with Lazy.nvim, LSP, and environment-specific configs |
| Vim | `.vimrc` | Lightweight fallback editor config |

### Terminal Emulators
| Tool | Config path | Description |
|------|-------------|-------------|
| Wezterm | `.config/wezterm/` | GPU-accelerated terminal with modular Lua config |
| Ghostty | `.config/ghostty/` | Fast native terminal emulator |
| Alacritty | `.config/alacritty/` | Minimal GPU-accelerated terminal |
| iTerm2 | `.config/iterm2/` | Feature-rich macOS terminal emulator |

### Shell
| Tool | Config path | Description |
|------|-------------|-------------|
| Zsh | `.zshrc` | Shell config with Oh My Zsh, plugins, and custom aliases |
| Starship | `.config/starship.toml` | Cross-shell prompt with git and language indicators |

### Multiplexer
| Tool | Config path | Description |
|------|-------------|-------------|
| Tmux | `.config/tmux/` | Terminal multiplexer with custom keybindings and gruvbox theme |

### Git & GitHub
| Tool | Config path | Description |
|------|-------------|-------------|
| Git | `.config/git/` | Global gitignore |
| GitHub CLI | `.config/gh/` | gh CLI auth and host config |
| GitHub Copilot | `.config/github-copilot/` | Copilot editor integration settings |

### CLI Tools
| Tool | Config path | Description |
|------|-------------|-------------|
| Eza | `.config/eza/` | Modern `ls` replacement with custom color theme |
| Karabiner | `.config/karabiner/` | macOS keyboard remapping and complex modifications |

### Dev Environment
| Tool | Config path | Description |
|------|-------------|-------------|
| Flutter | `.config/flutter/` | Flutter SDK settings and device preferences |
| Homebrew | `Brewfile` | Declarative list of all brew packages and casks |
| Herdr | `.config/herdr/` | Terminal session manager settings |

### AI Coding Assistants
| Tool | Config path | Description |
|------|-------------|-------------|
| Claude Code | `.claude/` | Agents, commands, skills, hooks, and project code rules |
| Codex CLI | `.codex/` | Rules, config, and shared skills (symlinked from `.claude/skills`) |
| Gemini CLI | `.gemini/` | Settings and shared skills (symlinked from `.claude/skills`) |

### Scripts
| Path | Description |
|------|-------------|
| `scripts/install/` | Modular install steps (stow, terminal, etc.) sourced by `install.sh` |
| `scripts/nvim/`, `scripts/tmux/` | Helper scripts for Neovim and tmux |
| `scripts/tmux-sessionizer` | Fuzzy-find and jump between tmux sessions |
| `scripts/herdr-sessionizer`, `scripts/herdr-clear-pane` | Herdr session helpers |
| `scripts/open-or-focus-tab` | Open or focus an existing terminal tab |


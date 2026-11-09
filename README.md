# dotfiles

My macOS development environment: Neovim, Ghostty, Herdr, Zsh and Claude Code — one repo, one install command, one theme for everything.

![Hero](docs/images/hero.png)

## Highlights

- **One command setup** — `./install.sh` walks through each component and asks before installing it.
- **Symlinks via GNU Stow** — edit files in the repo, changes apply instantly.
- **One theme everywhere** — switch Ghostty, Herdr, Neovim, Claude Code and fzf together with `scripts/theme-switch <name>`.
- **Safe by default** — existing configs are backed up to `~/.dotfiles-backup/`, never deleted.

## Install

Requires macOS and git.

```bash
git clone https://github.com/nxhung2304/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Machine-specific values and secrets go in `~/.env` (sourced by `.zshrc`, never committed), for example:

```bash
export IPHONE_16_UDID="..."
```

## Preview

| Neovim | Herdr |
|--------|-------|
| ![Neovim](docs/images/nvim.png) | ![Herdr](docs/images/herdr.png) |

![Theme switch](docs/images/theme-switch.gif)

## What's inside

| Area | Path | Notes |
|------|------|-------|
| Editor | `.config/nvim/` | Lazy.nvim, LSP, separate setups for VS Code and Xcode |
| Terminal | `.config/ghostty/` | Ghostty |
| Multiplexer | `.config/herdr/` | Command palette on `prefix+m`, theme switcher on `prefix+t`, per-project floating terminal on `ctrl+\` |
| Shell | `.zshrc`, `.config/starship.toml` | Oh My Zsh, zoxide, direnv, aliases |
| CLI | `.config/eza/`, `karabiner/`, `git/`, `gh/`, `ripgrep/` | Modern `ls`, key remapping, git config (delta, zdiff3) and global gitignore, ripgrep defaults |
| AI | `.claude/` | Agents, skills, hooks and code rules |
| Packages | `Brewfile` | Declarative Homebrew list |
| Scripts | `scripts/` | Installers, sessionizers, theme switcher |

## License

Personal configuration — use anything you like.

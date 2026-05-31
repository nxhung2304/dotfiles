# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Requirements

- Neovim >= 0.10 (LuaJIT build)
- Nerd Font (for icons)
- External tools for LSP servers — see `README.md` for per-language install commands
- Formatters: `rubocop`, `swiftformat`, `prettier`, `stylua`, `kotlin-language-server`

## Architecture

### Entry Point (`init.lua`)
Branches on `vim.g.vscode`: VS Code integration loads `lua/code/` only; standard Neovim loads `lua/user/plugins/` via Lazy.nvim then `lua/user/core/`.

### `lua/user/core/`
Loaded by `lua/user/core/init.lua` in this order:
1. `custom_command.lua` — user-defined Ex commands
2. `keymaps.lua` — global keymaps (uses `utils.keymap` wrapper)
3. `options.lua` — vim options
4. `autocmds.lua` — autocommands
5. Sidebar panels registered and keymaps set up (see `sidebar/CLAUDE.md`)

`configs.lua` — shared constants: icon sets for diagnostics, LSP kinds, etc. Import with `require("user.core.configs")`.

### `lua/user/plugins/`
Each file returns a Lazy.nvim plugin spec. Subdirectories group related specs:
- `lsp/` — `nvim-lspconfig` + Mason; `lsp/settings/` holds per-server option files
- `flutter/` — flutter-tools + utilities

Key plugins: `snacks.nvim` (picker, notifier, gh API, image rendering via kitty), `conform.nvim` (formatting), `nvim-cmp` (completion), `treesitter`, `which-key`.

### `lua/code/` (VS Code mode)
Minimal setup: only `options.lua` (sets `clipboard=unnamedplus`) and `lua/code/plugins/`.

### Custom Sidebar (`lua/user/core/sidebar/`)
Hand-built panel switcher — see `lua/user/core/sidebar/CLAUDE.md` for full details.
Panels: Files (`<leader>1`), Git (`<leader>2`), Search (`<leader>3`), LSP symbols (`<leader>4`), Marks (`<leader>5`), GitHub (`<leader>6`). Toggle: `<leader>ut`.

## Key Keymaps

| Key | Action |
|---|---|
| `jk` | Exit insert mode |
| `<C-s>` | Save file |
| `<C-f>` | Open tmux-sessionizer |
| `ga` | LSP code action |
| `]e` / `[e` | Next/prev error diagnostic |
| `<leader>cc` | Copy to clipboard (OSC52) |
| `<leader>ca` / `<leader>cr` | Copy absolute/relative path |

## LSP Setup Pattern

Servers are listed in `lua/user/plugins/lsp/init.lua`. Per-server options live in `lua/user/plugins/lsp/settings/<server>.lua` and are auto-loaded by the utils helper. To add a new server: add its name to the `servers` table and optionally create a settings file.

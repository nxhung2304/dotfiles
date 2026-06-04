<center>
    <a href="https://github.com/nguyenxuanhung2304/nvim/pulse">
      <img alt="Last commit" src="https://img.shields.io/github/last-commit/nguyenxuanhung2304/nvim?style=for-the-badge&logo=starship&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41"/>
    </a>
    <a href="https://github.com/nguyenxuanhung2304/nvim/blob/main/LICENSE">
      <img alt="License" src="https://img.shields.io/github/license/nguyenxuanhung2304/nvim?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/nguyenxuanhung2304/nvim/stargazers">
      <img alt="Stars" src="https://img.shields.io/github/stars/nguyenxuanhung2304/nvim?style=for-the-badge&logo=starship&color=c69ff5&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/nguyenxuanhung2304/nvim/issues">
      <img alt="Issues" src="https://img.shields.io/github/issues/nguyenxuanhung2304/nvim?style=for-the-badge&logo=bilibili&color=F5E0DC&logoColor=D9E0EE&labelColor=302D41" />
    </a>
</center>

Personal Neovim config powered by [lazy.nvim](https://github.com/folke/lazy.nvim). Supports standard Neovim, VS Code (via extension), and Xcode (via ShadowVim).

## Requirements

- Neovim >= **0.11** (LuaJIT build)
- Git >= **2.19.0**
- [Nerd Font](https://www.nerdfonts.com/)
- tmux (for Claude Code integration and sessionizer)

## LSP Servers

| Language | Server | Install |
|---|---|---|
| Ruby | `solargraph` | `gem install --user-install solargraph` |
| TypeScript/JS | `ts_ls`, `vtsls` | `npm install -g typescript typescript-language-server` |
| Vue | `volar` | `npm install -g @vue/language-server` |
| ESLint / JSON / CSS | `eslint`, `jsonls`, `cssls` | `npm i -g vscode-langservers-extracted` |
| Emmet | `emmet_ls` | `npm install -g emmet-ls` |
| Tailwind | `tailwindcss` | `npm install -g @tailwindcss/language-server` |
| Lua | `lua_ls` | `brew install lua-language-server` |
| Swift | `sourcekit` | Xcode CLI tools |
| PHP | `phpactor` | Composer |
| Python | `pyright` | `npm install -g pyright` |
| Kotlin | `kotlin_language_server` | `brew install kotlin-language-server` |
| Dart/Flutter | `dartls` | Managed by flutter-tools.nvim |

## Formatters

```sh
gem install rubocop
brew install swiftformat stylua kotlin-language-server
npm install -g prettier
```

## File Structure

```
~/.config/nvim
├── init.lua                        # Entry point — branches on vscode/shadowvim/standard
├── lua
│   ├── user/
│   │   ├── core/
│   │   │   ├── init.lua            # Loads core modules in order
│   │   │   ├── options.lua
│   │   │   ├── keymaps.lua
│   │   │   ├── autocmds.lua
│   │   │   ├── custom_command.lua
│   │   │   ├── configs.lua         # Shared icons/constants
│   │   │   ├── statusline.lua
│   │   │   ├── utils.lua
│   │   │   └── sidebar/            # Custom panel switcher
│   │   └── plugins/
│   │       ├── lsp/                # nvim-lspconfig + Mason
│   │       │   └── settings/       # Per-server option files
│   │       ├── flutter/            # flutter-tools + nvim-dap
│   │       ├── snacks.lua          # Picker, notifier, image rendering
│   │       ├── conform.lua         # Formatting
│   │       ├── cmp.lua             # Completion
│   │       ├── treesitter.lua
│   │       ├── git.lua
│   │       ├── rails.lua
│   │       ├── xcode.lua
│   │       └── ...
│   └── code/                       # VS Code mode only
│       ├── options.lua
│       └── plugins/
└── ftdetect/
```

## Keymaps

### General

| Key | Action |
|---|---|
| `jk` | Exit insert mode |
| `<C-s>` | Save file |
| `<C-f>` | Open tmux-sessionizer |
| `<C-h/j/k/l>` | Navigate splits |
| `<C-u>` / `<C-d>` | Scroll and center |
| `Q` | Replay macro `@q` |
| `<leader>q` | Replay last macro |

### LSP

| Key | Action |
|---|---|
| `ga` | Code action |
| `]e` / `[e` | Next / prev error |
| `]q` / `[q` | Next / prev quickfix |
| `<leader>ud` | Toggle sorted diagnostics |
| `<leader>uR` | Restart Neovim |

### Files & Clipboard

| Key | Action |
|---|---|
| `<leader>cc` | Copy to clipboard (OSC52) |
| `<leader>ca` | Copy absolute path |
| `<leader>cr` | Copy relative path |
| `<leader>cd` | Copy current diagnostic |
| `<leader>cs` | Substitute word in file |

### Sidebar panels

| Key | Panel |
|---|---|
| `<leader>1` | Files |
| `<leader>2` | Git |
| `<leader>3` | Search |
| `<leader>4` | Marks |
| `<leader>ut` | Toggle sidebar |

### Flutter (`<leader>F`)

| Key | Action |
|---|---|
| `<leader>Fr` | Run |
| `<leader>FD` | Debug |
| `<leader>Fs` | Hot Restart |
| `<leader>FR` | Hot Reload |
| `<leader>Fq` | Quit |
| `<leader>Fl` | Toggle Log |
| `<leader>Fd` | Devices |
| `<leader>Fe` | Emulators |
| `<leader>Fo` | Widget Outline |

### Debug / DAP (`<leader>d`)

| Key | Action |
|---|---|
| `<leader>dc` | Continue |
| `<leader>do` | Step Over |
| `<leader>di` | Step Into |
| `<leader>dO` | Step Out |
| `<leader>dt` | Terminate |
| `<leader>de` | REPL |
| `<leader>dv` | Toggle DAP panel |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |

### Claude Code integration

| Key | Action |
|---|---|
| `<leader>ac` | Send current line ref to Claude Code (tmux) |
| `<leader>ac` (visual) | Send selected range ref to Claude Code |

## Flutter Debug Workflow

```
1. <leader>Fd / <leader>Fe   — pick device or emulator
2. <leader>Fr / <leader>FD   — run or force-debug the app
3. <leader>db                — set breakpoints
4. <leader>dc                — continue past a breakpoint
5. <leader>do/di/dO          — step over / into / out
6. <leader>dv                — inspect variables and call stack
7. <leader>Fq / <leader>dt   — quit
```

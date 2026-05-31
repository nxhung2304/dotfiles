# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This directory implements a custom sidebar panel switcher for Neovim — no third-party sidebar plugin. All panels share a common base and register themselves into a central registry.

## Architecture

### `init.lua` — Registry & Controller
- `M.register(panel)` — registers a panel descriptor `{ id, label, icon, open(), close(), is_open(), get_win(), get_count?() }`
- `M.switch(id, opts)` — opens the target panel, closes all others; opens new panel first to avoid visual gaps
- `M.tabbar()` — builds the winbar string (active tab highlighted with `SidebarTabSel`, inactive with `SidebarTabNC`)
- `M.set_tabbar(win, extra)` — writes the winbar to a window while suppressing all autocmds (prevents NvimTree from reacting)
- `M.toggle()`, `M.next()`, `M.prev()` — navigation helpers
- `M.setup_keymaps()` — called once from `lua/user/core/init.lua`; binds `<leader>1`–`<leader>6` and `<leader>ut`

### `base.lua` — Shared Panel Infrastructure
Every panel gets a `state` table with `sidebar_buf`, `sidebar_win`, `source_win`, `entries`, `augroup`. Base provides:
- `open_win(state, opts)` — creates a `topleft vsplit` at width 52 with standard window options (number, relativenumber, winfixwidth, etc.)
- `set_lines(state, lines)` — safely writes to the nofile buffer (toggles `modifiable`)
- `close(state)` — closes window, wipes buf, clears augroup
- `on_win_closed(state, extra)` — registers a `WinClosed` autocmd to clean up state when window is closed externally
- `add_common_keymaps(state, close_fn)` — binds `q` (close), `>` (+4 width), `<lt>` (−4 width)

### Panels

| File | id | Highlights | Notes |
|---|---|---|---|
| `git.lua` | `git` | `GitSidebar*` | Parses `git status --porcelain`; staged/unstaged sections; `s`/`u`/`d`/`p`/`<CR>` keymaps |
| `search.lua` | `search` | — | Live grep via snacks |
| `symbol.lua` | `lsp` | `SymbolSidebar*` | LSP document symbols |
| `marks.lua` | `marks` | `MarksSidebar*` | Per-project marks persisted to `stdpath("data")/marks_sidebar/<sanitised-cwd>.json` |
| `diagnostics.lua` | `diagnostics` | `DiagSidebar*` | All-buffer diagnostics grouped by severity (ERROR → WARN → HINT → INFO); `get_count()` shows badge |
| `github.lua` | `github` | uses snacks gh highlight groups | Fetches PRs/issues via `snacks.gh.api`, projects via `gh project list --format json`; `T` translates content to Vietnamese using `gemini --model gemini-2.0-flash` |

### Adding a New Panel

1. Create `lua/user/core/sidebar/mypanel.lua` — implement `M.open()`, `M.close()`, `is_open()`, `get_win()` using `base` helpers.
2. Call `require("user.core.sidebar").register({ id = "mypanel", label = "Label", icon = "…", … })` inside a `vim.schedule` block at the bottom of the file.
3. Add `require "user.core.sidebar.mypanel"` to `lua/user/core/init.lua`.
4. Add a `<leader>N` keymap in `init.lua:M.setup_keymaps()`.

## Key Conventions
- Each panel owns its `state` as a module-local table; never share state across panels.
- `augroup` in state must be created at module load time (not inside `open()`), so `on_win_closed` can always clear it.
- Highlight groups are defined with `default = true` and re-applied on `ColorScheme` so they survive theme changes.
- The `no_badge` list in `init.lua:M.tabbar()` suppresses count badges for panels where a count is meaningless (`files`, `lsp`).

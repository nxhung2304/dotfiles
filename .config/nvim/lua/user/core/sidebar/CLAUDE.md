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
- `M.resize(delta)` — resizes the current sidebar window by `delta` columns (min 30)
- `M.setup_keymaps()` — called once from `lua/user/core/init.lua`; binds `<leader>1`–`<leader>4` and `<leader>ut`
- `no_badge` — panels whose `id` is `"files"` never show count badges in the tabbar

### `base.lua` — Shared Panel Infrastructure
Every panel gets a `state` table with `sidebar_buf`, `sidebar_win`, `source_win`, `entries`, `augroup`. Base provides:
- `open_win(state, opts)` — creates a `topleft vsplit` at width 52 with standard window options (number, relativenumber, winfixwidth, `undolevels=-1`, etc.)
- `set_lines(state, lines)` — safely writes to the nofile buffer (toggles `modifiable`)
- `close(state)` — closes window, wipes buf, clears augroup
- `on_win_closed(state, extra)` — registers a `WinClosed` autocmd to clean up state when window is closed externally
- `add_common_keymaps(state, close_fn)` — binds `q` (close), `>` (+4 width), `<lt>` (−4 width)
- `find_target_win(state)` — returns `source_win` if valid, else first non-special window
- **Persistence helpers** (used by `search.lua`):
  - `project_file(namespace, cwd)` — returns path to `stdpath("data")/<namespace>/<sanitised-cwd>.json`
  - `save_project_data(namespace, data, cwd)` — JSON-encodes and writes data
  - `load_project_data(namespace, cwd)` — reads and JSON-decodes; returns `nil` on missing/corrupt file

### Panels

| File | id | Highlights | Persistence | Notes |
|---|---|---|---|---|
| `search.lua` | `search` | `SearchSidebar*` | `search_sidebar/<cwd>.json` (history only) | Live grep via ripgrep; main fields: query/replace; filter fields (collapsible): include/exclude/folder; toggles: hidden(`h`), case-sensitive(`c`), whole-word(`w`), show-filters(`t`); per-project history with `[`/`]` browse; result collapsing (`z`); exclusion with undo (`d`/`u`); replace (`x`) |

### Adding a New Panel

1. Create `lua/user/core/sidebar/mypanel.lua` — implement `M.open()`, `M.close()`, `is_open()`, `get_win()` using `base` helpers.
2. Call `require("user.core.sidebar").register({ id = "mypanel", label = "Label", icon = "…", … })` inside a `vim.schedule` block at the bottom of the file.
3. Add `require "user.core.sidebar.mypanel"` to `lua/user/core/init.lua`.
4. Add a `<leader>N` keymap in `init.lua:M.setup_keymaps()` (currently `<leader>3`+ are free).

## Key Conventions
- Each panel owns its `state` as a module-local table; never share state across panels.
- `augroup` in state must be created at module load time (not inside `open()`), so `on_win_closed` can always clear it.
- Highlight groups are defined with `default = true` and re-applied on `ColorScheme` so they survive theme changes.
- The `no_badge` list in `init.lua:M.tabbar()` suppresses count badges for panels where a count is meaningless (`files`).
- Persistence uses `base.save/load_project_data` with a per-panel namespace; keys are cwd paths sanitised by replacing `/` with `%`.

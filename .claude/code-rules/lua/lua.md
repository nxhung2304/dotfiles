# Lua (Neovim config)

Conventions taken from the existing code in `.config/nvim/`. When a file already does it differently, follow that file (see Precedence in index.md).

## Format
- Format with `stylua` defaults: tabs, double quotes, 120 columns. Run `stylua <file>` only on files you create or already edit; do not reformat untouched files.
- Many older files are not stylua-clean. Do not reformat a whole file just to touch one function.

## Modules
- A helper module starts with `local M = {}` and ends with `return M`. A Lazy.nvim plugin file is a bare `return { ... }` spec.
- Public functions are `function M.name()`; everything else is `local function`, defined before its first use.
- Constants are `local UPPER_SNAKE = ...` at the top of the file. Named patterns, file names and suffixes count as constants.
- Load heavy or optional modules at the call site: `require(...)` inside the callback, or `pcall(require, ...)` for a plugin that may be absent.

## Neovim API
- Keymaps: `vim.keymap.set` with a `desc`. Files in `lua/user/core/` use the `utils.keymap` wrapper instead.
- Autocmds: `nvim_create_autocmd` with a `callback`. Give it a named group with `clear = true` when it can be registered more than once.
- User messages in new code: `vim.notify(message, level, { title = "..." })`. Some older core files use `print`; leave those as they are.
- Find a project root with `vim.fs.root`; do not shell out for it.

## Checks
- Load the changed module headless before reporting done: `nvim --headless -u NONE -c "lua require('<module>')" -c q`. Stub plugin modules the file requires.
- `Undefined global vim` from the language server is a missing lua_ls setting, not a code error.

-- Aerial-like symbols outline in a right-side vertical split. Standalone (not
-- part of the sidebar switcher). Reuses the documentSymbol cache maintained by
-- `user.core.symbol`.
local symbol = require("user.core.symbol")

local M = {}
local WIDTH = 40

local state = {
	buf        = nil,
	win        = nil,
	source_win = nil,
	entries    = {},
	augroup    = vim.api.nvim_create_augroup("SymbolsOutline", { clear = true }),
}
local ns = vim.api.nvim_create_namespace("SymbolsOutline")

-- ── highlights ──────────────────────────────────────────────────────────────
local function setup_hl()
	vim.api.nvim_set_hl(0, "SymbolsOutlineKind",    { link = "Type",   default = true })
	vim.api.nvim_set_hl(0, "SymbolsOutlineCurrent", { link = "Visual", default = true })
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })
setup_hl()

-- ── helpers ─────────────────────────────────────────────────────────────────
local function is_open()
	return state.win and vim.api.nvim_win_is_valid(state.win)
end

-- The editor window whose symbols we display: last known source, else any
-- normal (non-outline) window.
local function editor_win()
	if state.source_win
		and vim.api.nvim_win_is_valid(state.source_win)
		and state.source_win ~= state.win
		and vim.bo[vim.api.nvim_win_get_buf(state.source_win)].buftype == "" then
		return state.source_win
	end
	for _, w in ipairs(vim.api.nvim_list_wins()) do
		if w ~= state.win and vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "" then
			return w
		end
	end
end

-- Pre-order flatten: display lines + parallel jump-target entries.
local function build(symbols, depth, lines, entries)
	for _, sym in ipairs(symbols) do
		local range  = sym.selectionRange or sym.range
		local full   = sym.range or range
		local icon   = symbol.icon(sym.kind)
		local indent = string.rep("  ", depth)
		table.insert(lines, indent .. icon .. sym.name)
		table.insert(entries, {
			lnum = range.start.line + 1,
			col  = range.start.character,
			s    = full.start.line, -- containment range for cursor tracking
			e    = full["end"].line,
			icol = #indent,
			ncol = #(indent .. icon),
		})
		if sym.children and #sym.children > 0 then
			build(sym.children, depth + 1, lines, entries)
		end
	end
end

local function set_lines(lines)
	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = false
end

-- ── render / track ──────────────────────────────────────────────────────────
function M.render()
	if not is_open() then return end
	local win = editor_win()
	local buf = win and vim.api.nvim_win_get_buf(win)
	local symbols = buf and symbol.get_symbols(buf)

	local lines, entries = {}, {}
	if symbols and #symbols > 0 then
		build(symbols, 0, lines, entries)
	else
		lines = { "  No symbols" }
	end
	state.entries = entries
	set_lines(lines)

	vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
	for i, e in ipairs(entries) do
		vim.api.nvim_buf_set_extmark(state.buf, ns, i - 1, e.icol, {
			end_col = e.ncol, hl_group = "SymbolsOutlineKind",
		})
	end
	M.track()
end

-- Highlight (and follow) the deepest symbol containing the source cursor.
function M.track()
	if not is_open() then return end
	local win = editor_win()
	if not win then return end

	-- clear only the current-line highlight (id 1), keep icon extmarks
	pcall(vim.api.nvim_buf_del_extmark, state.buf, ns, 1)

	local cur = vim.api.nvim_win_get_cursor(win)[1] - 1
	local hit
	for i, e in ipairs(state.entries) do
		if e.s and cur >= e.s and cur <= e.e then hit = i end
	end
	if not hit then return end

	vim.api.nvim_buf_set_extmark(state.buf, ns, hit - 1, 0, {
		id = 1, line_hl_group = "SymbolsOutlineCurrent",
	})
	if vim.api.nvim_get_current_win() ~= state.win then
		pcall(vim.api.nvim_win_set_cursor, state.win, { hit, 0 })
	end
end

local function jump()
	local entry = state.entries[vim.api.nvim_win_get_cursor(state.win)[1]]
	if not entry then return end
	local win = editor_win()
	if not win then return end
	vim.api.nvim_set_current_win(win)
	pcall(vim.api.nvim_win_set_cursor, win, { entry.lnum, entry.col })
	vim.cmd("normal! zz")
end

-- ── open / close / toggle ─────────────────────────────────────────────────────
function M.open()
	if is_open() then
		vim.api.nvim_set_current_win(state.win)
		return
	end
	state.source_win = vim.api.nvim_get_current_win()

	state.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[state.buf].buftype    = "nofile"
	vim.bo[state.buf].bufhidden  = "wipe"
	vim.bo[state.buf].filetype   = "symbolsoutline"
	vim.bo[state.buf].modifiable = false
	vim.bo[state.buf].undolevels = -1

	vim.cmd("botright vsplit")
	state.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.win, state.buf)
	vim.api.nvim_win_set_width(state.win, WIDTH)

	local wo = vim.wo[state.win]
	wo.number         = false
	wo.relativenumber = false
	wo.signcolumn     = "no"
	wo.wrap           = false
	wo.winfixwidth    = true
	wo.cursorline     = true
	wo.winbar         = "%#Title# 󰊕 Symbols%*"

	local map = function(lhs, rhs) vim.keymap.set("n", lhs, rhs, { buffer = state.buf, nowait = true }) end
	map("<CR>", jump)
	map("q", M.close)
	map("r", M.render)

	-- return focus to the editor and fetch/render
	vim.api.nvim_set_current_win(state.source_win)
	symbol.request(vim.api.nvim_win_get_buf(state.source_win), vim.schedule_wrap(M.render))
	M.render()

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
		group = state.augroup,
		callback = vim.schedule_wrap(M.render),
	})
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = state.augroup,
		callback = vim.schedule_wrap(M.track),
	})
	-- follow the focused editor window
	vim.api.nvim_create_autocmd("WinEnter", {
		group = state.augroup,
		callback = function()
			local w = vim.api.nvim_get_current_win()
			if w ~= state.win and vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "" then
				state.source_win = w
				vim.schedule(M.render)
			end
		end,
	})
	vim.api.nvim_create_autocmd("WinClosed", {
		group   = state.augroup,
		pattern = tostring(state.win),
		once    = true,
		callback = function()
			state.win, state.buf, state.entries = nil, nil, {}
			vim.api.nvim_clear_autocmds({ group = state.augroup })
		end,
	})
end

function M.close()
	if not is_open() then return end
	local win = state.win
	state.win, state.buf, state.entries = nil, nil, {}
	vim.api.nvim_clear_autocmds({ group = state.augroup })
	vim.api.nvim_win_close(win, true)
end

function M.toggle()
	if is_open() then M.close() else M.open() end
end

vim.keymap.set("n", "<leader>o", M.toggle, { desc = "Toggle symbols outline" })

return M

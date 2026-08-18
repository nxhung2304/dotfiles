-- Project-wide diagnostics outline in a right-side vertical split. Standalone,
-- mirrors `user.core.symbols_outline` structurally. Meant to be paired with it
-- via edgy.nvim so both stack on the right edge.
local M = {}

local SEVERITY_ICON = {
	[vim.diagnostic.severity.ERROR] = "󰅚 ",
	[vim.diagnostic.severity.WARN]  = "󰀪 ",
	[vim.diagnostic.severity.INFO]  = "󰋽 ",
	[vim.diagnostic.severity.HINT]  = "󰌶 ",
}
local SEVERITY_HL = {
	[vim.diagnostic.severity.ERROR] = "DiagnosticError",
	[vim.diagnostic.severity.WARN]  = "DiagnosticWarn",
	[vim.diagnostic.severity.INFO]  = "DiagnosticInfo",
	[vim.diagnostic.severity.HINT]  = "DiagnosticHint",
}

local state = {
	buf          = nil,
	win          = nil,
	source_win   = nil,
	entries      = {},
	errors_only  = true, -- default: hide warnings/info/hints
	augroup      = vim.api.nvim_create_augroup("DiagnosticsOutline", { clear = true }),
}
local ns = vim.api.nvim_create_namespace("DiagnosticsOutline")

-- ── helpers ─────────────────────────────────────────────────────────────────
local function is_open()
	return state.win and vim.api.nvim_win_is_valid(state.win)
end

-- The editor window to jump into: last known source, else any normal
-- (non-outline) window.
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

local function set_lines(lines)
	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = false
end

-- Diagnostics for every buffer in the project, grouped by file and sorted by
-- path, then by position within the file.
local function collect_by_file()
	local max_severity = state.errors_only
		and vim.diagnostic.severity.ERROR
		or vim.diagnostic.severity.WARN
	local diags = vim.diagnostic.get(nil, { severity = { min = max_severity } })

	local by_buf = {}
	for _, d in ipairs(diags) do
		by_buf[d.bufnr] = by_buf[d.bufnr] or {}
		table.insert(by_buf[d.bufnr], d)
	end

	local files = {}
	for bufnr, list in pairs(by_buf) do
		table.sort(list, function(a, b)
			if a.lnum ~= b.lnum then return a.lnum < b.lnum end
			return a.col < b.col
		end)
		table.insert(files, {
			bufnr = bufnr,
			path  = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":."),
			diags = list,
		})
	end
	table.sort(files, function(a, b) return a.path < b.path end)
	return files
end

-- ── render ──────────────────────────────────────────────────────────────────
function M.render()
	if not is_open() then return end
	local files = collect_by_file()

	local lines, entries, hls = {}, {}, {}
	if #files > 0 then
		for _, file in ipairs(files) do
			table.insert(lines, "󰈔 " .. file.path)
			table.insert(entries, { bufnr = file.bufnr, lnum = file.diags[1].lnum + 1, col = file.diags[1].col })
			for _, d in ipairs(file.diags) do
				local icon = SEVERITY_ICON[d.severity] or "󰝾 "
				local msg  = d.message:gsub("\n%s*", " ")
				table.insert(lines, "  " .. icon .. msg)
				table.insert(entries, { bufnr = file.bufnr, lnum = d.lnum + 1, col = d.col })
				table.insert(hls, { line = #lines - 1, hl = SEVERITY_HL[d.severity], icol = 2, ncol = 2 + #icon })
			end
		end
	else
		lines = { "  No diagnostics" }
	end
	state.entries = entries
	set_lines(lines)

	vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
	for _, h in ipairs(hls) do
		vim.api.nvim_buf_set_extmark(state.buf, ns, h.line, h.icol, {
			end_col = h.ncol, hl_group = h.hl,
		})
		vim.api.nvim_buf_set_extmark(state.buf, ns, h.line, h.ncol, {
			end_line = h.line + 1, hl_group = h.hl, hl_eol = false,
		})
	end
end

local function jump()
	local entry = state.entries[vim.api.nvim_win_get_cursor(state.win)[1]]
	if not entry then return end
	local win = editor_win()
	if not win then return end
	vim.api.nvim_set_current_win(win)
	vim.api.nvim_win_set_buf(win, entry.bufnr)
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
	vim.bo[state.buf].filetype   = "diagnosticsoutline"
	vim.bo[state.buf].modifiable = false
	vim.bo[state.buf].undolevels = -1

	vim.cmd("botright vsplit")
	state.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.win, state.buf)

	local wo = vim.wo[state.win]
	wo.number         = false
	wo.relativenumber = false
	wo.signcolumn     = "no"
	wo.wrap           = true
	wo.cursorline     = true
	wo.winbar         = "%#Title# 󰒡 Diagnostics%*"

	local map = function(lhs, rhs) vim.keymap.set("n", lhs, rhs, { buffer = state.buf, nowait = true }) end
	map("<CR>", jump)
	map("q", M.close)
	map("r", M.render)
	map("w", M.toggle_errors_only)

	-- return focus to the editor and render
	vim.api.nvim_set_current_win(state.source_win)
	M.render()

	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		group = state.augroup,
		callback = vim.schedule_wrap(M.render),
	})
	-- keep track of the last focused editor window for jump targets
	vim.api.nvim_create_autocmd("WinEnter", {
		group = state.augroup,
		callback = function()
			local w = vim.api.nvim_get_current_win()
			if w ~= state.win and vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "" then
				state.source_win = w
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

function M.toggle_errors_only()
	state.errors_only = not state.errors_only
	M.render()
end

return M

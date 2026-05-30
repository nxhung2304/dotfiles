local M = {}
local base = require("user.core.sidebar.base")

local state = {
	sidebar_buf = nil,
	sidebar_win = nil,
	source_win  = nil,
	entries     = {},
	augroup     = vim.api.nvim_create_augroup("DiagSidebar", { clear = true }),
}

local SEV = vim.diagnostic.severity
local sev_order  = { SEV.ERROR, SEV.WARN, SEV.HINT, SEV.INFO }
local sev_label  = { [SEV.ERROR] = "Errors", [SEV.WARN] = "Warnings", [SEV.HINT] = "Hints", [SEV.INFO] = "Info" }
local sev_icon   = { [SEV.ERROR] = "󰅚 ", [SEV.WARN] = "󰀦 ", [SEV.HINT] = "󰌶 ", [SEV.INFO] = " " }
local sev_hl     = { [SEV.ERROR] = "DiagnosticError", [SEV.WARN] = "DiagnosticWarn",
                     [SEV.HINT]  = "DiagnosticHint",  [SEV.INFO] = "DiagnosticInfo" }

local function setup_hl()
	vim.api.nvim_set_hl(0, "DiagSidebarKey",      { link = "Function", default = true })
	vim.api.nvim_set_hl(0, "DiagSidebarHintDesc", { link = "Comment",  default = true })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })
setup_hl()

local ns = vim.api.nvim_create_namespace("DiagSidebarHl")
local _count_cache = nil

function M.get_count()
	if _count_cache ~= nil then return _count_cache > 0 and _count_cache or nil end
	local diags = vim.diagnostic.get(nil, { severity = { min = SEV.WARN } })
	_count_cache = #diags
	return _count_cache > 0 and _count_cache or nil
end

local function render()
	if not base.is_valid(state) then return end

	-- Collect all diagnostics across all buffers, grouped by severity
	local by_sev = {}
	for _, sev in ipairs(sev_order) do by_sev[sev] = {} end

	for _, diag in ipairs(vim.diagnostic.get(nil)) do
		local sev = diag.severity or SEV.WARN
		if by_sev[sev] then
			table.insert(by_sev[sev], diag)
		end
	end

	-- Count errors+warnings for badge
	_count_cache = #by_sev[SEV.ERROR] + #by_sev[SEV.WARN]

	local lines   = {}
	local entries = {}
	local has_any = false

	for _, sev in ipairs(sev_order) do
		local diags = by_sev[sev]
		if #diags > 0 then
			has_any = true
			-- Section header
			table.insert(lines,   "▾ " .. sev_label[sev] .. " (" .. #diags .. ")")
			table.insert(entries, { type = "header", severity = sev })

			for _, d in ipairs(diags) do
				local bufname = vim.api.nvim_buf_get_name(d.bufnr or 0)
				local short   = vim.fn.fnamemodify(bufname, ":.")
				local loc     = short .. ":" .. (d.lnum + 1)
				local msg     = d.message:gsub("\n", " "):sub(1, 60)
				table.insert(lines,   "  " .. sev_icon[sev] .. loc .. "  " .. msg)
				table.insert(entries, { type = "diag", bufnr = d.bufnr, lnum = d.lnum, col = d.col, severity = sev })
			end

			-- spacing between sections
			table.insert(lines, ""); table.insert(entries, { type = "empty" })
		end
	end

	if not has_any then
		lines   = { "  no diagnostics" }
		entries = { { type = "empty" } }
	end

	state.entries = entries
	base.set_lines(state, lines)

	vim.api.nvim_buf_clear_namespace(state.sidebar_buf, ns, 0, -1)
	for i, entry in ipairs(entries) do
		if entry.type == "header" then
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, sev_hl[entry.severity], i - 1, 0, -1)
		elseif entry.type == "diag" then
			-- only icon colored, rest is Normal
			local icon_len = #sev_icon[entry.severity] + 2  -- 2 = leading spaces
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, sev_hl[entry.severity], i - 1, 2, icon_len)
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "Normal", i - 1, icon_len, -1)
		end
	end

	require("user.core.sidebar").set_tabbar(state.sidebar_win)
end

local function setup_keymaps()
	local opts = { buffer = state.sidebar_buf, nowait = true }

	vim.keymap.set("n", "<CR>", function()
		local line  = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
		local entry = state.entries[line]
		if not entry or entry.type ~= "diag" then return end
		local win = base.find_target_win(state)
		if not win then return end
		vim.api.nvim_set_current_win(win)
		if entry.bufnr and vim.api.nvim_buf_is_valid(entry.bufnr) then
			vim.api.nvim_set_current_buf(entry.bufnr)
		end
		vim.api.nvim_win_set_cursor(win, { entry.lnum + 1, entry.col or 0 })
		vim.cmd("normal! zz")
	end, opts)

	vim.keymap.set("n", "r", function() render() end, opts)
	base.add_common_keymaps(state, M.close)
end

function M.open()
	local k, h = "%#DiagSidebarKey#", "%#DiagSidebarHintDesc#"
	base.open_win(state, {
		filetype   = "DiagSidebar",
		statusline = " " .. k .. "r" .. h .. ":refresh",
		cursorline = true,
	})

	setup_keymaps()
	render()
	vim.api.nvim_set_current_win(state.sidebar_win)

	vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufWritePost", "InsertLeave" }, {
		group    = state.augroup,
		callback = function()
			if base.is_valid(state) then vim.schedule(render) end
		end,
	})
	base.on_win_closed(state, function() state.entries = {} end)
end

function M.close()
	base.close(state)
	state.entries = {}
end

vim.api.nvim_create_autocmd("DiagnosticChanged", {
	group    = vim.api.nvim_create_augroup("DiagSidebarCount", { clear = true }),
	callback = function() _count_cache = nil end,
})

vim.schedule(function()
	require("user.core.sidebar").register({
		id        = "diag",
		label     = "Diag",
		icon      = "",
		open      = M.open,
		close     = M.close,
		is_open   = function() return base.is_valid(state) end,
		get_win   = function() return state.sidebar_win end,
		get_count = M.get_count,
	})
end)

return M

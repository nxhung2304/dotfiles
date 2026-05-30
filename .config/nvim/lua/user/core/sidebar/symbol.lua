local M = {}
local base = require("user.core.sidebar.base")

local METHOD_KINDS = { [6] = true, [9] = true, [12] = true } -- Method, Constructor, Function

local kind_hl = {
	[6] = "SymbolSidebarMethod",  -- Method
	[9] = "SymbolSidebarMethod",  -- Constructor
	[12] = "SymbolSidebarMethod", -- Function
	[5] = "SymbolSidebarType",    -- Class
	[11] = "SymbolSidebarType",   -- Interface
	[23] = "SymbolSidebarType",   -- Struct
	[10] = "SymbolSidebarConst",  -- Enum
	[14] = "SymbolSidebarConst",  -- Constant
	[22] = "SymbolSidebarConst",  -- EnumMember
	[7] = "SymbolSidebarField",   -- Property
	[8] = "SymbolSidebarField",   -- Field
	[13] = "SymbolSidebarVar",    -- Variable
}

local ns_kinds  = vim.api.nvim_create_namespace("SymbolSidebarKinds")
local ns_cursor = vim.api.nvim_create_namespace("SymbolSidebarCursor")

local function setup_highlights()
	vim.api.nvim_set_hl(0, "SymbolSidebarMethod",  { link = "Function" })
	vim.api.nvim_set_hl(0, "SymbolSidebarType",    { link = "Type" })
	vim.api.nvim_set_hl(0, "SymbolSidebarConst",   { link = "Constant" })
	vim.api.nvim_set_hl(0, "SymbolSidebarField",   { link = "Identifier" })
	vim.api.nvim_set_hl(0, "SymbolSidebarVar",     { link = "Normal" })
	vim.api.nvim_set_hl(0, "SymbolSidebarCurrent", { link = "PmenuSel" })
	vim.api.nvim_set_hl(0, "SymbolSidebarWinBar",  { link = "FloatTitle" })
	vim.api.nvim_set_hl(0, "SymbolSidebarBorder",  { link = "FloatBorder" })
end

local state = {
	sidebar_buf = nil,
	sidebar_win = nil,
	source_buf = nil,
	source_win = nil,
	locations = {}, -- maps sidebar line -> { lnum, col, hl }
	raw_symbols = {},
	method_only = true,
	filter = "",
	augroup = vim.api.nvim_create_augroup("SymbolSidebar", { clear = true }),
}

local breadcrumb_cache = {} -- { [bufnr] = symbols }

local kind_icons = {
	[1] = "󰈙 ", -- File
	[2] = "󰏗 ", -- Module
	[3] = "󰌗 ", -- Namespace
	[4] = "󰏖 ", -- Package
	[5] = "󰌗 ", -- Class
	[6] = "󰊕 ", -- Method
	[7] = "󰆧 ", -- Property
	[8] = "󰇽 ", -- Field
	[9] = " ", -- Constructor
	[10] = "󰕘 ", -- Enum
	[11] = "󰕘 ", -- Interface
	[12] = "󰊕 ", -- Function
	[13] = "󰀫 ", -- Variable
	[14] = "󰏿 ", -- Constant
	[15] = "󰀬 ", -- String
	[16] = "󰎠 ", -- Number
	[17] = "◩ ", -- Boolean
	[18] = "󰅪 ", -- Array
	[19] = "󰅩 ", -- Object
	[20] = "󰌋 ", -- Key
	[21] = "󰟢 ", -- Null
	[22] = "󰕘 ", -- EnumMember
	[23] = "󰌗 ", -- Struct
	[24] = " ", -- Event
	[25] = "󰆕 ", -- Operator
	[26] = "󰊄 ", -- TypeParameter
}

local function flatten_symbols(symbols, depth, lines, locs, method_only)
	depth = depth or 0
	for _, sym in ipairs(symbols) do
		local include = not method_only or METHOD_KINDS[sym.kind]
		if include then
			local icon   = kind_icons[sym.kind] or "• "
			local indent = string.rep("  ", depth)
			table.insert(lines, indent .. icon .. sym.name)

			local range = sym.selectionRange or sym.range
			table.insert(locs, {
				lnum     = range.start.line,
				col      = range.start.character,
				hl       = kind_hl[sym.kind] or "Normal",
				icon_end = #indent + #icon,  -- byte end of icon (for icon-only highlight)
			})
		end

		if sym.children and #sym.children > 0 then
			flatten_symbols(sym.children, depth + 1, lines, locs, method_only)
		end
	end
end

local function set_winbar()
	if not base.is_valid(state) then return end
	local mode = state.method_only and "m" or "a"
	local hint = mode .. (state.filter ~= "" and ("  /" .. state.filter) or "")
	require("user.core.sidebar").set_tabbar(state.sidebar_win, hint)
end

local function highlight_current()
	if not base.is_valid(state) or not state.source_win or not vim.api.nvim_win_is_valid(state.source_win) then
		return
	end
	local cursor = vim.api.nvim_win_get_cursor(state.source_win)
	local cur_lnum = cursor[1] - 1 -- 0-indexed

	local match = 1
	for i, loc in ipairs(state.locations) do
		if loc.lnum <= cur_lnum then
			match = i
		end
	end

	if #state.locations > 0 then
		vim.api.nvim_buf_clear_namespace(state.sidebar_buf, ns_cursor, 0, -1)
		vim.api.nvim_buf_set_extmark(state.sidebar_buf, ns_cursor, match - 1, 0, {
			line_hl_group = "SymbolSidebarCurrent",
			priority = 200,
		})
		-- scroll sidebar to keep match visible without moving cursor
		local sidebar_height = vim.api.nvim_win_get_height(state.sidebar_win)
		local top = vim.fn.line("w0", state.sidebar_win) - 1
		local bot = top + sidebar_height - 1
		if match - 1 < top or match - 1 > bot then
			vim.api.nvim_win_set_cursor(state.sidebar_win, { match, 0 })
		end
	end
end

local function apply_kind_highlights(locs)
	vim.api.nvim_buf_clear_namespace(state.sidebar_buf, ns_kinds, 0, -1)
	for i, loc in ipairs(locs) do
		if loc.hl and loc.icon_end then
			-- icon colored, name stays Normal
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns_kinds, loc.hl,    i - 1, 0,           loc.icon_end)
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns_kinds, "Normal",  i - 1, loc.icon_end, -1)
		end
	end
end

local function render_symbols()
	if not base.is_valid(state) then return end
	local lines = {}
	local locs = {}
	flatten_symbols(state.raw_symbols, 0, lines, locs, state.method_only)

	if state.filter ~= "" then
		local f = state.filter:lower()
		local fl, fc = {}, {}
		for i, line in ipairs(lines) do
			if line:lower():find(f, 1, true) then
				table.insert(fl, line); table.insert(fc, locs[i])
			end
		end
		lines, locs = fl, fc
	end
	if #lines == 0 then
		lines = { state.filter ~= "" and "  (no match)" or "  (no symbols)" }
	end

	state.locations = locs
	base.set_lines(state, lines)
	set_winbar()
	apply_kind_highlights(locs)
	highlight_current()
end

local function has_document_symbol(bufnr)
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		if client.server_capabilities.documentSymbolProvider then
			return true
		end
	end
	return false
end

function M.refresh()
	if not base.is_valid(state) then return end

	local bufnr = state.source_buf
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end
	if not has_document_symbol(bufnr) then
		base.set_lines(state, { "  (no LSP)" })
		set_winbar()
		return
	end

	-- Render immediately from cache for instant tab switching
	local cached = breadcrumb_cache[bufnr]
	if cached then
		state.raw_symbols = cached
		render_symbols()
		return
	end

	-- No cache yet: fetch from LSP
	local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
	vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result)
		if err or not result or not base.is_valid(state) then return end
		state.raw_symbols = result
		breadcrumb_cache[bufnr] = result
		render_symbols()
	end)
end

local function setup_keymaps()
	local buf = state.sidebar_buf
	local opts = { buffer = buf, nowait = true }

	vim.keymap.set("n", "<CR>", function()
		local line = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
		local loc = state.locations[line]
		if loc and state.source_win and vim.api.nvim_win_is_valid(state.source_win) then
			vim.api.nvim_set_current_win(state.source_win)
			vim.api.nvim_win_set_cursor(state.source_win, { loc.lnum + 1, loc.col })
			vim.cmd("normal! zz")
		end
	end, opts)

	vim.keymap.set("n", "r", function() M.refresh() end, opts)
	vim.keymap.set("n", "m", function()
		state.method_only = not state.method_only
		render_symbols()
	end, opts)
	vim.keymap.set("n", "/", function()
		local input = vim.fn.input("Filter: ", state.filter)
		state.filter = input
		render_symbols()
	end, opts)
	vim.keymap.set("n", "<Esc>", function()
		if state.filter ~= "" then
			state.filter = ""
			render_symbols()
		end
	end, opts)
	base.add_common_keymaps(state, M.close)
end

local function setup_autocmds()
	local group = state.augroup

	vim.api.nvim_create_autocmd({ "BufWritePost", "LspAttach" }, {
		group = group,
		buffer = state.source_buf,
		callback = function() M.refresh() end,
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = group,
		buffer = state.source_buf,
		callback = highlight_current,
	})

	base.on_win_closed(state)

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			setup_highlights()
			if base.is_valid(state) then
				apply_kind_highlights(state.locations)
				set_winbar()
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function()
			if not base.is_valid(state) then return end
			local win = vim.api.nvim_get_current_win()
			if win == state.source_win then
				local buf = vim.api.nvim_get_current_buf()
				if buf ~= state.source_buf then
					state.source_buf = buf
					vim.api.nvim_clear_autocmds({ group = group })
					setup_autocmds()
				end
				M.refresh()
			end
		end,
	})
end

function M.open()
	-- Prefer a real file window over nofile/special buffers (e.g. other sidebars)
	state.source_buf = vim.api.nvim_get_current_buf()
	base.open_win(state, {
		filetype    = "SymbolSidebar",
		cursorline  = false,
		winhighlight = table.concat({
			"Normal:NormalFloat",
			"WinSeparator:SymbolSidebarBorder",
			"WinBar:SymbolSidebarWinBar",
			"WinBarNC:SymbolSidebarWinBar",
		}, ","),
	})

	-- Re-capture source_buf after open_win may have changed source_win
	if state.source_win and vim.api.nvim_win_is_valid(state.source_win) then
		state.source_buf = vim.api.nvim_win_get_buf(state.source_win)
	end

	setup_highlights()
	setup_keymaps()
	setup_autocmds()
	M.refresh()
	vim.api.nvim_set_current_win(state.sidebar_win)
end

function M.close()
	base.close(state)
	state.locations = {}
end

function M.toggle()
	if base.is_valid(state) then
		M.close()
	else
		M.open()
	end
end

-- Breadcrumb (navic replacement) ------------------------------------------

local function find_crumbs(symbols, cursor_line)
	for _, sym in ipairs(symbols) do
		local range = sym.range or sym.selectionRange
		if range and cursor_line >= range.start.line and cursor_line <= range["end"].line then
			local crumbs = { sym }
			if sym.children and #sym.children > 0 then
				local child = find_crumbs(sym.children, cursor_line)
				if child then
					vim.list_extend(crumbs, child)
				end
			end
			return crumbs
		end
	end
	return nil
end

function M.get_breadcrumb()
	local bufnr = vim.api.nvim_get_current_buf()
	local symbols = breadcrumb_cache[bufnr]
	if not symbols then return "" end

	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local crumbs = find_crumbs(symbols, cursor_line)
	if not crumbs or #crumbs == 0 then return "" end

	local parts = {}
	for i, sym in ipairs(crumbs) do
		local icon = kind_icons[sym.kind] or "• "
		local hl = (i % 2 == 1) and "NavicHighlight1" or "NavicHighlight2"
		table.insert(parts, "%#" .. hl .. "#" .. icon .. sym.name .. "%*")
	end
	return " > " .. table.concat(parts, " %#WinBarPath#>%* ")
end

function M.attach(bufnr)
	local function fetch()
		if not has_document_symbol(bufnr) then return end
		local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
		vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result)
			if not err and result then
				breadcrumb_cache[bufnr] = result
				if base.is_valid(state) and state.source_buf == bufnr then
					state.raw_symbols = result
					render_symbols()
				end
			end
		end)
	end

	fetch()
	vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
		buffer = bufnr,
		callback = fetch,
	})
	vim.api.nvim_create_autocmd("BufDelete", {
		buffer = bufnr,
		once = true,
		callback = function() breadcrumb_cache[bufnr] = nil end,
	})
end

-- Register with sidebar manager (deferred so user.sidebar is definitely loaded)
vim.schedule(function()
	require("user.core.sidebar").register({
		id = "lsp",
		label = "LSP",
		icon = "󰘦 (L)",
		open = M.open,
		close = M.close,
		is_open = function() return base.is_valid(state) end,
		get_win = function() return state.sidebar_win end,
		get_count = function() return #state.locations end,
	})
end)

return M

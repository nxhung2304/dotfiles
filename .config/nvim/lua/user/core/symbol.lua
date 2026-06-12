local M = {}

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

local breadcrumb_cache = {} -- { [bufnr] = symbols }

local function has_document_symbol(bufnr)
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		if client.server_capabilities.documentSymbolProvider then
			return true
		end
	end
	return false
end

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

	local MAX_CRUMBS = 3
	local truncated = #crumbs > MAX_CRUMBS
	local visible = truncated and { unpack(crumbs, #crumbs - MAX_CRUMBS + 1) } or crumbs

	local parts = {}
	for i, sym in ipairs(visible) do
		local icon = kind_icons[sym.kind] or "• "
		local hl = (i % 2 == 1) and "NavicHighlight1" or "NavicHighlight2"
		table.insert(parts, "%#" .. hl .. "#" .. icon .. sym.name .. "%*")
	end
	local prefix = truncated and " %#WinBarPath#…%* > " or " > "
	return prefix .. table.concat(parts, " %#WinBarPath#>%* ")
end

function M.get_current_symbol()
	local bufnr = vim.api.nvim_get_current_buf()
	local symbols = breadcrumb_cache[bufnr]
	if not symbols then return "" end

	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local crumbs = find_crumbs(symbols, cursor_line)
	if not crumbs or #crumbs == 0 then return "" end

	local sym = crumbs[#crumbs]
	return (kind_icons[sym.kind] or "• ") .. sym.name
end

function M.pick_symbol()
	local bufnr = vim.api.nvim_get_current_buf()
	local symbols = breadcrumb_cache[bufnr]
	if not symbols or #symbols == 0 then
		vim.notify("No symbols cached", vim.log.levels.WARN)
		return
	end

	local items = {}
	local function collect(syms, depth)
		for _, sym in ipairs(syms) do
			local icon = kind_icons[sym.kind] or "• "
			local indent = string.rep("  ", depth)
			local range = sym.selectionRange or sym.range
			table.insert(items, {
				label = indent .. icon .. sym.name,
				lnum  = range.start.line + 1,
				col   = range.start.character,
			})
			if sym.children and #sym.children > 0 then
				collect(sym.children, depth + 1)
			end
		end
	end
	collect(symbols, 0)

	vim.ui.select(items, {
		prompt = "Go to symbol",
		format_item = function(item) return item.label end,
	}, function(item)
		if not item then return end
		vim.api.nvim_win_set_cursor(0, { item.lnum, item.col })
		vim.cmd("normal! zz")
	end)
end

function M.attach(bufnr)
	local function fetch()
		if not has_document_symbol(bufnr) then return end
		local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
		vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result)
			if not err and result then
				breadcrumb_cache[bufnr] = result
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

return M

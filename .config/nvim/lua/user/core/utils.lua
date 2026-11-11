local Configs = require("user.core.configs")

local M = {}

function M.keymap(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }

	if opts then
		options = vim.tbl_extend("force", options, opts)
	end

	vim.keymap.set(mode, lhs, rhs, options)
end

function M.signs()
	return {
		{ name = "DiagnosticSignError", text = "" },
		{ name = "DiagnosticSignWarn", text = "" },
		{ name = "DiagnosticSignHint", text = "" },
		{ name = "DiagnosticSignInfo", text = "" },
	}
end

function M.on_load(name, fn)
	local Config = require("lazy.core.config")
	if Config.plugins[name] and Config.plugins[name]._.loaded then
		fn(name)
	else
		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyLoad",
			callback = function(event)
				if event.data == name then
					fn(name)
					return true
				end
			end,
		})
	end
end

local function highlight_fg(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
end

local function set_winbar_highlights()
	vim.api.nvim_set_hl(0, "NavicHighlight1", { fg = highlight_fg("Constant"), bold = true })
	vim.api.nvim_set_hl(0, "NavicHighlight2", { fg = highlight_fg("Type"), bold = true })
	vim.api.nvim_set_hl(0, "WinBarPath", { fg = highlight_fg("Comment") })
	vim.api.nvim_set_hl(0, "WinBarFilename", { fg = highlight_fg("String"), bold = true })
	vim.api.nvim_set_hl(0, "WinBar", { fg = highlight_fg("Comment"), bg = "NONE", bold = true })
	vim.api.nvim_set_hl(0, "WinBarNC", { fg = highlight_fg("Comment"), bg = "NONE" })
end

set_winbar_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_winbar_highlights })

M.get_filepath_with_navic = function()
	local filepath = vim.fn.expand("%:~:.")

	local path_parts = vim.split(filepath, "/")
	local filename = path_parts[#path_parts]
	local path = table.concat(path_parts, "/", 1, #path_parts - 1)

	local file_icon, icon_hl = require("nvim-web-devicons").get_icon(filename, nil, { default = true })
	local hl_def = vim.api.nvim_get_hl(0, { name = icon_hl, link = false })
	local icon_color = hl_def.fg and string.format("#%06x", hl_def.fg)
	if icon_color then
		vim.api.nvim_set_hl(0, "WinBarFileIcon", { fg = icon_color })
		file_icon = "%#WinBarFileIcon#" .. (file_icon or "") .. "%*"
	else
		file_icon = file_icon or ""
	end

	local colored_filepath = ""
	if path ~= "" then
		colored_filepath = "%#WinBarPath#" .. path .. "/%#WinBarFilename# " .. file_icon .. " " .. filename .. "%*"
	else
		colored_filepath = "%#WinBarFilename#" .. " " .. file_icon .. " " .. filename .. "%*"
	end

	local ok, sidebar = pcall(require, "user.core.symbol")
	if ok then
		local crumb = sidebar.get_breadcrumb()
		if crumb and crumb ~= "" then
			return colored_filepath .. crumb
		end
	end

	return colored_filepath
end

local hover_diagnostics_namespace = vim.api.nvim_create_namespace("user.hover_diagnostics")

local diagnostic_highlight_groups = {
	[vim.diagnostic.severity.ERROR] = "DiagnosticError",
	[vim.diagnostic.severity.WARN] = "DiagnosticWarn",
	[vim.diagnostic.severity.INFO] = "DiagnosticInfo",
	[vim.diagnostic.severity.HINT] = "DiagnosticHint",
}

local diagnostic_icons = {
	[vim.diagnostic.severity.ERROR] = Configs.icons.diagnostics[1].text,
	[vim.diagnostic.severity.WARN] = Configs.icons.diagnostics[2].text,
	[vim.diagnostic.severity.HINT] = Configs.icons.diagnostics[3].text,
	[vim.diagnostic.severity.INFO] = Configs.icons.diagnostics[4].text,
}

local function is_diagnostic_under_cursor(diagnostic, cursor_col)
	local end_col = diagnostic.end_lnum == diagnostic.lnum and diagnostic.end_col or math.huge
	return diagnostic.col <= cursor_col and cursor_col < math.max(end_col, diagnostic.col + 1)
end

local function sort_diagnostics_cursor_first(diagnostics, cursor_col)
	local under_cursor = {}
	for _, diagnostic in ipairs(diagnostics) do
		under_cursor[diagnostic] = is_diagnostic_under_cursor(diagnostic, cursor_col)
	end
	table.sort(diagnostics, function(a, b)
		if under_cursor[a] ~= under_cursor[b] then
			return under_cursor[a]
		end
		return a.severity < b.severity
	end)
end

local function diagnostic_markdown_lines(bufnr, lnum, cursor_col)
	local diagnostics = vim.diagnostic.get(bufnr, { lnum = lnum })
	sort_diagnostics_cursor_first(diagnostics, cursor_col)

	local lines = {}
	local line_highlight_groups = {}
	for _, diagnostic in ipairs(diagnostics) do
		local source = diagnostic.source and (" (" .. diagnostic.source .. ")") or ""
		local code = diagnostic.code and (" [" .. diagnostic.code .. "]") or ""
		local message_lines = vim.split(diagnostic.message, "\n")
		message_lines[1] = diagnostic_icons[diagnostic.severity] .. " " .. message_lines[1] .. source .. code
		for _, message_line in ipairs(message_lines) do
			table.insert(lines, message_line)
			table.insert(line_highlight_groups, diagnostic_highlight_groups[diagnostic.severity])
		end
	end
	return lines, line_highlight_groups
end

M.hover_with_diagnostics = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local winid = vim.api.nvim_get_current_win()
	local cursor = vim.api.nvim_win_get_cursor(winid)
	local lnum = cursor[1] - 1
	local cursor_col = cursor[2]

	local function position_params(client)
		return vim.lsp.util.make_position_params(winid, client.offset_encoding)
	end

	vim.lsp.buf_request_all(bufnr, "textDocument/hover", position_params, function(results)
		if vim.api.nvim_get_current_buf() ~= bufnr then
			return
		end

		local lines, diagnostic_line_highlight_groups = diagnostic_markdown_lines(bufnr, lnum, cursor_col)
		for _, response in pairs(results) do
			local contents = response.result and response.result.contents
			if contents then
				local hover_lines = vim.lsp.util.convert_input_to_markdown_lines(contents)
				if #lines > 0 and #hover_lines > 0 then
					table.insert(lines, "---")
				end
				vim.list_extend(lines, hover_lines)
			end
		end

		if #lines == 0 then
			vim.notify("No information available", vim.log.levels.INFO)
			return
		end

		local float_bufnr = vim.lsp.util.open_floating_preview(lines, "markdown", { focus_id = "textDocument/hover" })
		for row, highlight_group in ipairs(diagnostic_line_highlight_groups) do
			vim.hl.range(float_bufnr, hover_diagnostics_namespace, highlight_group, { row - 1, 0 }, { row - 1, -1 })
		end
	end)
end

M.lsp_on_attach = function(client, bufnr)
	if vim.bo[bufnr].filetype == "markdown" then
		client:stop()
		return
	end

	local keymap = M.keymap

	vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

	local ok, symbol = pcall(require, "user.core.symbol")
	if ok then symbol.attach(bufnr) end

	keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", { buffer = bufnr, desc = "Go to Definition" })
	keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { buffer = bufnr, desc = "Go to References" })
	keymap("n", "K", M.hover_with_diagnostics, { buffer = bufnr, desc = "Hover Documentation and Diagnostics" })
	keymap("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", { buffer = bufnr, desc = "Code Action" })
	keymap("n", "gl", "<cmd>lua vim.lsp.codelens.run()<CR>", { buffer = bufnr, desc = "Run Code Lens" })

	if client.server_capabilities.inlayHintProvider then
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		keymap("n", "<leader>uh", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
		end, { buffer = bufnr, desc = "Toggle Inlay Hints" })
	end

	if client.server_capabilities.codeLensProvider then
		if vim.fn.has("nvim-0.12") == 1 then
			vim.lsp.codelens.enable(true, { bufnr = bufnr })
		else
			vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
				buffer = bufnr,
				callback = function()
					vim.lsp.codelens.refresh()
				end,
			})
		end
	end

	if client.server_capabilities.documentHighlightProvider then
		local group = vim.api.nvim_create_augroup("LspDocumentHighlight_" .. bufnr, { clear = true })

		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.document_highlight()
			end,
		})

		vim.api.nvim_create_autocmd("CursorMoved", {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.clear_references()
			end,
		})
	end
end

-- Fix Lsp cannot start with flutter-tools:https://github.com/nvim-flutter/flutter-tools.nvim
function M.attach_dartls_to_all_buffers()
	local dartls_clients = vim.lsp.get_clients({ name = "dartls" })
	if #dartls_clients == 0 then
		print("No dartls client found")
		return
	end

	local dartls_client = dartls_clients[1]
	local attached_count = 0

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_is_valid(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			local filetype = vim.bo[buf].filetype

			-- Check if it's a dart file
			if filetype == "dart" or name:match("%.dart$") then
				local clients = vim.lsp.get_clients({ bufnr = buf })
				local has_dartls = false

				for _, client in pairs(clients) do
					if client.name == "dartls" then
						has_dartls = true
						break
					end
				end

				if not has_dartls then
					vim.lsp.buf_attach_client(buf, dartls_client.id)
					attached_count = attached_count + 1
					print("Attached dartls to buffer " .. buf)
				end
			end
		end
	end

	print("Attached dartls to " .. attached_count .. " buffers")
end

function M.confirm(prompt, on_confirm)
	vim.ui.select({ "Yes", "No" }, { prompt = prompt }, function(choice)
		if choice == "Yes" then
			on_confirm()
		end
	end)
end

function M.open_sorted_diagnostics(severity_filter)
	local diagnostics = vim.diagnostic.get(nil, severity_filter and { severity = severity_filter })

	table.sort(diagnostics, function(a, b)
		if a.severity ~= b.severity then
			return a.severity < b.severity
		end
		return a.lnum < b.lnum
	end)

	vim.diagnostic.setqflist(diagnostics)
	vim.cmd("copen")
	vim.cmd("wincmd p")
end

return M

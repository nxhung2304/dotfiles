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

M.get_filepath_with_navic = function()
	local filepath = vim.fn.expand("%:~:.")
	local aquaColor = "#83a598"
	local orangeColor = "#d65d0e"
	local filenameColor = "#b8bb26"
	local pathColor = "#928374"

	-- Highlight groups (giữ nguyên)
	vim.api.nvim_set_hl(0, "NavicHighlight1", { fg = orangeColor, bold = true })
	vim.api.nvim_set_hl(0, "NavicHighlight2", { fg = aquaColor, bold = true })
	vim.api.nvim_set_hl(0, "WinBarPath", { fg = pathColor })
	vim.api.nvim_set_hl(0, "WinBarFilename", { fg = filenameColor, bold = true })

	-- Split path và filename
	local path_parts = vim.split(filepath, "/")
	local filename = path_parts[#path_parts]
	local path = table.concat(path_parts, "/", 1, #path_parts - 1)

	-- File icon từ nvim-web-devicons
	local devicons = require("nvim-web-devicons")
	local file_icon, icon_color = devicons.get_icon_color(filename, vim.fn.expand("%:e"))
	if icon_color then
		vim.api.nvim_set_hl(0, "WinBarFileIcon", { fg = icon_color })
		file_icon = "%#WinBarFileIcon#" .. (file_icon or "") .. "%*"
	else
		file_icon = file_icon or ""
	end

	-- Xây dựng colored_filepath
	local colored_filepath = ""
	if path ~= "" then
		colored_filepath = "%#WinBarPath#" .. path .. "/%#WinBarFilename# " .. file_icon .. " " .. filename .. "%*"
	else
		colored_filepath = "%#WinBarFilename#" .. " " .. file_icon .. " " .. filename .. "%*"
	end

	local icons = require("user.core.configs").icons.kind
	if require("nvim-navic").is_available() then
		local data = require("nvim-navic").get_data()
		if data and #data > 0 then
			local context_parts = {}
			for i, context in ipairs(data) do
				local name = context.name
				local kind = context.kind
				local icon = icons[kind] or " "
				local highlight_group = (i % 2 == 1) and "NavicHighlight1" or "NavicHighlight2" -- Xen kẽ màu
				table.insert(context_parts, "%#" .. highlight_group .. "#" .. icon .. name .. "%*")
			end
			local context_string = table.concat(context_parts, " > ")
			return colored_filepath .. " > " .. context_string
		end
	end

	return colored_filepath
end

M.lsp_on_attach = function(client, bufnr)
	local keymap = M.keymap
	local navic = require("nvim-navic")

	-- Enable completion triggered by <c-x><c-o>
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

	keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", { buffer = bufnr, desc = "Go to Definition" })
	keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { buffer = bufnr, desc = "Go to References" })
	keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { buffer = bufnr, desc = "Hover Documentation" })
	keymap("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", { buffer = bufnr, desc = "Code Action" })
	keymap("n", "gl", "<cmd>lua vim.lsp.codelens.run()<CR>", { buffer = bufnr, desc = "Run Code Lens" })

	if client.server_capabilities.codeLensProvider then
		vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
			buffer = bufnr,
			callback = vim.lsp.codelens.refresh,
		})
	end

	if client.server_capabilities.documentSymbolProvider then
		navic.attach(client, bufnr)
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
			local filetype = vim.api.nvim_buf_get_option(buf, "filetype")

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

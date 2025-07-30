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

	vim.api.nvim_set_hl(0, "NavicHighlight1", { fg = orangeColor, bold = true })
	vim.api.nvim_set_hl(0, "NavicHighlight2", { fg = aquaColor, bold = true })
	vim.api.nvim_set_hl(0, "WinBarPath", { fg = pathColor })
	vim.api.nvim_set_hl(0, "WinBarFilename", { fg = filenameColor, bold = true })

	local path_parts = vim.split(filepath, "/")
	local filename = path_parts[#path_parts]
	local path = table.concat(path_parts, "/", 1, #path_parts - 1)
	local icons = require("user.core.configs").icons.lsp

	local colored_filepath = ""
	if path ~= "" then
		colored_filepath = "%#WinBarPath#" .. path .. "/%#WinBarFilename#" .. " " .. icons.File .. filename .. "%*"
	else
		colored_filepath = "%#WinBarFilename#" .. "" .. icons.File .. filename .. "%*"
	end

	if require("nvim-navic").is_available() then
		local data = require("nvim-navic").get_data()
		if data and #data > 0 then
			local context_string = ""
			local first_context = data[1]
			local first_name = first_context.name
			local first_kind = first_context.kind
			local first_icon = icons[first_kind] or " "
			local highlighted_first = "%#NavicHighlight1#" .. first_icon .. first_name .. "%*"
			context_string = highlighted_first

			if #data >= 2 then
				local second_context = data[2]
				local second_name = second_context.name
				local second_kind = second_context.kind
				local second_icon = icons[second_kind] or " "
				local highlighted_second = "%#NavicHighlight2#" .. second_icon .. second_name .. "%*"
				context_string = context_string .. " > " .. highlighted_second
			end
			return colored_filepath .. " > " .. context_string
		end
	end
	return colored_filepath
end

M.lsp_on_attach = function(client, bufnr)
	local keymap = M.keymap
	local navic = require("nvim-navic")

	keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", { buffer = bufnr })
	keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { buffer = bufnr })
	keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { buffer = bufnr })
	keymap("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", { buffer = bufnr })

	if client.server_capabilities.documentSymbolProvider then
		navic.attach(client, bufnr)
	end
end

-- Fix Lsp cannot start with flutter-tools:https://github.com/nvim-flutter/flutter-tools.nvim
function M.attach_dartls_to_all_buffers()
	local dartls_clients = vim.lsp.get_active_clients({ name = "dartls" })
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
				local clients = vim.lsp.get_active_clients({ bufnr = buf })
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

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

function M.get_relative_path()
	local path = vim.fn.expand("%:~:.")
	return path ~= "" and path or "[No Name]"
end

M.get_filepath_with_navic = function()
	local filepath = vim.fn.expand("%:~:.")
	local blueColor = "#00afef"
	vim.api.nvim_set_hl(0, "NavicHighlight", { fg = blueColor, bold = true })

	if require("nvim-navic").is_available() then
		local data = require("nvim-navic").get_data()
		if data and #data > 0 then
			local first_context = data[1]
			local context_name = first_context.name

			local highlighted_context = "%#NavicHighlight#" .. context_name .. "%*"

			return filepath .. " > " .. highlighted_context
		end
	end

	return filepath
end

return M

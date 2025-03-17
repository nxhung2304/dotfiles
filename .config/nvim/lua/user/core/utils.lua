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

	vim.api.nvim_set_hl(0, "NavicHighlight1", { fg = orangeColor, bold = true })
	vim.api.nvim_set_hl(0, "NavicHighlight2", { fg = aquaColor, bold = true })

	if require("nvim-navic").is_available() then
		local data = require("nvim-navic").get_data()
		if data and #data > 0 then
			local context_string = ""

			local first_context = data[1]
			local first_name = first_context.name
			local highlighted_first = "%#NavicHighlight1#" .. first_name .. "%*"

			context_string = highlighted_first

			if #data >= 2 then
				local second_context = data[2]
				local second_name = second_context.name
				local highlighted_second = "%#NavicHighlight2#" .. second_name .. "%*"

				context_string = context_string .. " > " .. highlighted_second
			end

			return filepath .. " > " .. context_string
		end
	end

	return filepath
end

return M

return {
	{
		"luisiacc/gruvbox-baby",
		branch = "main",
		init = function()
			local currentColorscheme = vim.g.colors_name
			if currentColorscheme ~= "gruvbox-baby" then
				return
			end
			local colors = require("gruvbox-baby.colors").config()
			vim.api.nvim_set_hl(
				0,
				"BufferLineBufferSelected",
				{ fg = colors.gray, bg = colors.none, italic = true, sp = "#242424" }
			)
			vim.api.nvim_set_hl(
				0,
				"BufferLineCloseButtonSelected",
				{ fg = colors.gray, bg = colors.none, italic = true, sp = "#242424" }
			)
			vim.api.nvim_set_hl(
				0,
				"BufferLineDevIconLuaSelected",
				{ fg = colors.blue_gray, bg = colors.none, italic = true, sp = "#242424" }
			)
			vim.api.nvim_set_hl(
				0,
				"BufferLineDevIconLuaInactive",
				{ fg = colors.blue_gray, bg = colors.none, italic = true, sp = "#242424" }
			)
			vim.api.nvim_set_hl(
				0,
				"BufferLineBufferVisible",
				{ fg = colors.comment, bg = colors.none, italic = true, sp = "#242424" }
			)
		end,
		config = function()
			vim.cmd.colorscheme("gruvbox-baby")

			local yellow_to_blue_highlights = {
				"QuickFixLine",
			}

			for _, hl_group in ipairs(yellow_to_blue_highlights) do
				vim.api.nvim_set_hl(0, hl_group, {
					bg = "#1e3a5f",
					fg = "#ffffff",
				})
			end
		end,
	},
}

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
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- latte, frappe, macchiato, mocha
				background = { -- :h background
					light = "latte",
					dark = "mocha",
				},
				transparent_background = true, -- disables setting the background color.
				float = {
					transparent = false, -- enable transparent floating windows
					solid = false, -- use solid styling for floating windows, see |winborder|
				},
				show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
				term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
				dim_inactive = {
					enabled = false, -- dims the background color of inactive window
					shade = "dark",
					percentage = 0.15, -- percentage of the shade to apply to the inactive window
				},
				no_italic = false, -- Force no italic
				no_bold = false, -- Force no bold
				no_underline = false, -- Force no underline
				styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
					comments = { "italic" }, -- Change the style of comments
					conditionals = { "italic" },
					loops = {},
					functions = {},
					keywords = {},
					strings = {},
					variables = {},
					numbers = {},
					booleans = {},
					properties = {},
					types = {},
					operators = {},
				},
				color_overrides = {},
				custom_highlights = {},
				default_integrations = true,
				auto_integrations = true,
				integrations = {
					cmp = true,
					gitsigns = true,
					nvimtree = true,
					treesitter = true,
					notify = true,
					mini = {
						enabled = true,
						indentscope_color = "",
					},
          avante = false,
					-- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
				},
			})

			-- setup must be called before loading
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}

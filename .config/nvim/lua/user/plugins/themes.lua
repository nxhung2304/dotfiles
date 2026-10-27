local persist_file = vim.fn.stdpath("data") .. "/colorscheme.txt"

local function read_saved()
	local f = io.open(persist_file, "r")
	if f then
		local name = f:read("*l")
		f:close()
		if name and name ~= "" then
			return name
		end
	end
	return "kanagawa-wave"
end

local function save_colorscheme(name)
	local f = io.open(persist_file, "w")
	if f then
		f:write(name)
		f:close()
	end
end

local function highlight_fg(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
end

local function apply_statusline()
	local bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
	vim.api.nvim_set_hl(0, "StatusLine", { fg = highlight_fg("Function"), bg = bg })
	vim.api.nvim_set_hl(0, "StatusLineNC", { fg = highlight_fg("Comment"), bg = bg })
end

return {
	{
		"rockyzhang24/arctic.nvim",
		dependencies = { "rktjmp/lush.nvim" },
		name = "arctic",
		branch = "v2",
		lazy = false,
		priority = 1000,
		config = function() end,
	},
	{
		"projekt0n/github-nvim-theme",
		name = "github-theme",
		lazy = false,
		priority = 999,
		config = function()
			require("github-theme").setup({})

			-- Reapply statusline overrides on every colorscheme change
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = apply_statusline,
			})

			-- :CS — open Snacks colorscheme picker and persist selection
			vim.api.nvim_create_user_command("CS", function()
				Snacks.picker.colorschemes({
					confirm = function(picker, item)
						picker:close()
						if item then
							vim.cmd("colorscheme " .. item.text)
							save_colorscheme(item.text)
						end
					end,
				})
			end, { nargs = 0 })

			vim.keymap.set("n", "<leader>uc", "<cmd>CS<cr>", { desc = "Pick colorscheme" })

			vim.cmd("colorscheme " .. read_saved())
		end,
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true,
			colors = {
				theme = {
					all = {
						ui = {
							bg_gutter = "none",
						},
					},
				},
			},
			overrides = function(colors)
				local theme = colors.theme
				return {
					NormalFloat = { bg = "none" },
					FloatBorder = { fg = theme.ui.bg_p2, bg = "none" },
					FloatTitle = { fg = theme.ui.special, bg = "none", bold = true },
					SnacksPickerBorder = { fg = theme.ui.bg_p2, bg = "none" },
					Pmenu = { fg = theme.ui.pmenu.fg, bg = "none" },
					PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
					WinSeparator = { fg = theme.ui.bg_p1, bg = "none" },
					WinBar = { fg = theme.ui.fg_dim, bg = "none" },
					WinBarNC = { fg = theme.ui.nontext, bg = "none" },
					CursorLineNr = { fg = theme.syn.special1, bg = "none", bold = true },
				}
			end,
		},
	},
}

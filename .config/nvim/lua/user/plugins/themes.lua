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
	return "gruvbox"
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
	vim.api.nvim_set_hl(0, "StatusLine", { fg = highlight_fg("Identifier"), bg = bg })
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
		"ellisonleao/gruvbox.nvim",
		lazy = false,
		priority = 1000,
		opts = function()
			local palette = require("gruvbox").palette
			local background = palette.dark0
			local subtle_line = palette.dark2
			local overrides = {
				SignColumn = { bg = background },
				FoldColumn = { bg = background },
				NormalFloat = { bg = background },
				FloatBorder = { fg = subtle_line, bg = background },
				FloatTitle = { fg = palette.light4, bg = background, bold = true },
				SnacksPickerBorder = { fg = subtle_line },
				Pmenu = { bg = background },
				PmenuSel = { bg = palette.dark1, bold = true },
				WinSeparator = { fg = palette.dark1, bg = background },
				WinBar = { fg = palette.light4, bg = background },
				WinBarNC = { fg = palette.gray, bg = background },
				Folded = { fg = palette.gray, bg = background },
			}
			for _, color in ipairs({ "Red", "Green", "Yellow", "Blue", "Purple", "Aqua", "Orange" }) do
				overrides["Gruvbox" .. color .. "Sign"] = { bg = background }
			end
			return {
				italic = { strings = false },
				overrides = overrides,
			}
		end,
	},
}

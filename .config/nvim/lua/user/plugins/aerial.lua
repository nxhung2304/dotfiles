local Configs = require("user.core.configs")

return {
	"stevearc/aerial.nvim",
	-- event = {
	-- 	"BufReadPre",
	-- 	"LspAttach",
	-- },
	opts = {
		layout = {
			max_width = { 40, 0.25 },
			min_width = 20,
		},
		filter_kind = {
			"Class",
			"Constructor",
			"Enum",
			"Interface",
			"Module",
			"Method",
			-- "Struct",
		},
		attach_mode = "global", -- luôn sync theo buffer hiện tại

		show_guides = true, -- vẽ tree nhìn rõ hơn

		highlight_closest = true,

		open_automatic = true,

		autojump = true,
		highlight_on_hover = true,
		highlight_on_jump = 250,
		highlight = {
			aerial_current = "Visual",
			aerial_guide = "Comment",
		},

		icons = Configs.icons.kind,
	},
	keys = {
		{
			"<leader>uo",
			function()
				local is_aerial_open = require("aerial").is_open()
				if is_aerial_open then
					vim.cmd("AerialClose")
				else
					pcall(function()
						vim.cmd("NvimTreeClose")
					end)
				end
				vim.cmd("AerialOpen")
			end,
			desc = "Toggle Aerial",
		},
		{
			"}",
			"<cmd>AerialNext<CR>",
			desc = "Next symbol",
		},
		{
			"{",
			"<cmd>AerialPrev<CR>",
			desc = "Previous symbol",
		},
	},
}

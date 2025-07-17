return {
	"stevearc/aerial.nvim",
	event = {
		"BufReadPre",
		"LspAttach"
	},
	opts = {
		filter_kind = {
			"Class",
			"Constructor",
			"Enum",
			"Interface",
			"Module",
			"Method",
			-- "Struct",
		},
		autojump = true,
		highlight_on_hover = true,
		highlight_on_jump = 250,
		highlight = {
			aerial_current = "Visual",
			aerial_guide = "Comment",
		},
	},
	keys = {
		{
			"<leader>a",
			function()
				local is_aerial_open = require("aerial").is_open()
				if is_aerial_open then
					vim.cmd("AerialClose")
				else
					pcall(function()
						require("dapui").close()
						vim.cmd("NvimTreeClose")
					end)
				end
				vim.cmd("AerialOpen")

			end,
			desc = "Toggle Aerial",
		},
	},
}

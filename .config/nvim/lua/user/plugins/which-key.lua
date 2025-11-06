return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		win = {
			border = "single",
		},
		preset = "modern",
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.add({
			mode = { "n", "v" },
			{ "<leader>c", desc = "Code" },
			{ "<leader>C", desc = "Conflict" },
			{ "<leader>g", desc = "Git" },
			{ "<leader>s", desc = "Search" },
			{ "<leader>x", desc = "Xcode" },
			{ "<leader>d", desc = "Debugger" },
			{ "<leader>F", desc = "Flutter" },
			{ "<leader>r", desc = "Rails" },
			{ "<leader>u", desc = "UI" },
		})

		wk.setup(opts)
	end,
}

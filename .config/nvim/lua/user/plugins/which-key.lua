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
			{ "<leader>g", desc = "Git" },
			{ "<leader>s", desc = "Search" },
			{ "<leader>x", desc = "Xcode" },
			{ "<leader>F", desc = "Flutter" },
			{ "<leader>r", desc = "Rails nav" },
			{ "<leader>R", desc = "Rails runtime" },
			{ "<leader>u", desc = "UI" },
			{ "<leader>t", desc = "Test" },
			{ "<leader>q", desc = "Macro" },
			{ "<leader>cn", desc = "Swap item with next (vim-swap)" },
			{ "<leader>cp", desc = "Swap item with previous (vim-swap)" },
		})

		wk.setup(opts)
	end,
}

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
			{ "<leader>a", desc = "AI" },
			{ "<leader>c", desc = "Code" },
			{ "<leader>C", desc = "Claude Code" },
			{ "<leader>d", desc = "Debug" },
			{ "<leader>g", desc = "Git" },
			{ "<leader>s", desc = "Search" },
			{ "<leader>F", desc = "Flutter" },
			{ "<leader>r", desc = "Rails nav" },
			{ "<leader>R", desc = "Rails runtime" },
			{ "<leader>u", desc = "UI" },
			{ "<leader>t", desc = "Test" },
			{ "<leader>x", desc = "Xcode" },
			{ "<leader>y", desc = "Copy" },
		})

		wk.setup(opts)
	end,
}

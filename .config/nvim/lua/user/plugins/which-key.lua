return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	-- keys = { "<leader>", "<C-w>", '"', "'", "`", "c", "v", "g" },
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
			{ "<leader>C", desc = "Conflict" },
			{ "<leader>c", desc = "Code" },
			{ "<leader>g", desc = "Git" },
			{ "<leader>s", desc = "Search" },
			{ "<leader>x", desc = "Xcode" },
			{ "<leader>d", desc = "Debugger" },
			{ "<leader>u", desc = "UI" },
			{ "<leader>F", desc = "Flutter" },
			{ "<leader>r", desc = "Rest API" },
		})
		wk.setup(opts)
	end,
}

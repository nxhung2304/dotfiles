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
			{ "<leader>s", desc = "Search" },
		})
		wk.setup(opts)
	end,
}

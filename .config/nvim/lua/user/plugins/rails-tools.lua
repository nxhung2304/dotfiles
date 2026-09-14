return {
	{
		"nxhung2304/rails-tools.nvim",
		dir = "~/Dev/personal/rails-tools.nvim",
		lazy = false,
		config = function()
			require("rails-tools").setup()
		end,
	},
}

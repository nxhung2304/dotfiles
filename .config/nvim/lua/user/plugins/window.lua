return {
	"folke/edgy.nvim",
	event = "VeryLazy",
	init = function()
		vim.opt.laststatus = 3
		vim.opt.splitkeep = "screen"
	end,
	opts = {
		right = {
			{
				title = "Outline symbols",
				ft = "aerial",
			},
			{
				title = "Log",
				ft = "log",
				size = {
					width = 0.3
				}
			},
		},
	},
}

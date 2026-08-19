-- Stacks the symbols outline and diagnostics outline on the right edge:
-- symbols on top (70% height), diagnostics on the bottom (30% height).
return {
	"folke/edgy.nvim",
	event = "VeryLazy",
	opts = {
		right = {
			{ ft = "symbolsoutline", size = { height = 0.7, width = 35 } },
			{ ft = "diagnosticsoutline", size = { height = 0.3, width = 35 } },
		},
	},
}

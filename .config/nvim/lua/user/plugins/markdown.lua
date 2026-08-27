return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-web-devicons" },
	opts = {
		completions = { lsp = { enabled = true } },
	},
	keys = {
		{
			"<leader>um",
			function()
				require("render-markdown").toggle()
			end,
			desc = "Toggle markdown render",
		},
	},
}

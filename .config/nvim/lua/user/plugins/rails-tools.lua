return {
	{
		"nxhung2304/rails-tools.nvim",
		dir = "~/Dev/personal/rails-tools.nvim",
		lazy = false,
		config = function()
			require("rails-tools").setup({
				cmp = { dedupe_with_lsp = { "ruby-lsp", "ruby_lsp" } },
			})
		end,
	},
}

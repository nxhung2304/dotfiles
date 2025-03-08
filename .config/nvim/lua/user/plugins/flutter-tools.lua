return {
	"nvim-flutter/flutter-tools.nvim",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"stevearc/dressing.nvim",
	},
	opts = {
		lsp = {
			settings = {
				analysisExcludedFolders = {
					vim.fn.expand("$HOME/snap/flutter/common/flutter"),
					vim.fn.expand("$HOME/.pub-cache"),
				},
				showTodos = false,
				maxFileSize = 50000,
			},
		},
	},
}

local utils = require("user.core.utils")
return {
	"nvim-flutter/flutter-tools.nvim",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"stevearc/dressing.nvim",
	},
	opts = {
		lsp = {
			on_attach = utils.lsp_on_attach,
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

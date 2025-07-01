local utils = require("user.core.utils")

return {
	'akinsho/flutter-tools.nvim',
	ft = {
		'dart'
	},
	dependencies = {
		'nvim-lua/plenary.nvim',
		'stevearc/dressing.nvim',
	},
	config = function()
		require('flutter-tools').setup({
			flutter_path = vim.fn.system("which flutter"):gsub("\n", ""),

			root_patterns = { ".git", "pubspec.yaml" },

			lsp = {
				color = {
					enabled = true,
					background = false,
					virtual_text = false,
				},

				flags = {
					debounce_text_changes = 150,
				},

				on_attach = utils.lsp_on_attach
			},

			dev_log = {
				enabled = false,
			},

			closing_tags = {
				highlight = "Comment",
				prefix = " // ",
				enabled = true
			},
		})
	end
}

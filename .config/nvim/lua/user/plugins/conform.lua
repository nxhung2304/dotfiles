return {
	"stevearc/conform.nvim",
	opts = {
		formatters = {
			rubocop = {
				args = { "--auto-correct", "--format", "quiet", "--stderr", "--stdin", "$FILENAME" },
			},
		},
		formatters_by_ft = {
			lua = { "stylua" },
			go = { "goimports", "gofumpt" },
			python = { "isort", "black" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			ruby = {
				"rubocop",
			},
			eruby = {
				"htmlbeautifier",
			},
			html = {
				"prettier",
			},
			dart = {
				"dartformat",
			},
			vue = {
				"prettier",
			},
			css = {
				"prettier",
			},
			json = {
				"prettier",
			},
			swift = {
				"swiftformat",
			},
			kotlin = {
				"ktlint",
			},
			java = {
				"google-java-format",
			},
		},
	},
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
}

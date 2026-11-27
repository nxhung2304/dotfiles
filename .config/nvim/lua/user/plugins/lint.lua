return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		local ktlint_default_editorconfig = vim.fn.stdpath("config") .. "/ktlint-android.editorconfig"
		lint.linters.ktlint.args = { "--reporter=json", "--stdin", "--editorconfig=" .. ktlint_default_editorconfig }

		lint.linters_by_ft = {
			eruby = { "erb_lint" },
			swift = { "swiftlint" },
			kotlin = { "ktlint" },
		}

		vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}

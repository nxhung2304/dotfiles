return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters.erb_lint.cmd = "erblint"
		lint.linters.erb_lint.args = { "--format", "compact" }

		lint.linters_by_ft = {
			eruby = { "erb_lint" },
		}

		vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}

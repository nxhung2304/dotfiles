return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = { "Trouble", "TroubleToggle", "TroubleRefresh", "TroubleQuickfix" },
	keys = {
		{ "<leader>ut", "<cmd>Trouble quickfix toggle<cr>", { desc = "Toggle quickfix" } },
	},
	opts = {},
	config = function()
		require("trouble").setup({
			auto_open = false,
			auto_close = false,
			auto_preview = true,
			auto_jump = false,
			mode = "quickfix",
			severity = vim.diagnostic.severity.ERROR,
			cycle_results = false,
		})
	end,
}

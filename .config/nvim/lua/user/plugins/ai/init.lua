return {
	"greggh/claude-code.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("claude-code").setup({
			window = {
				position = "vertical",
        split_ratio = 0.4,
			},
		})
		vim.keymap.set("n", "<C-\\>", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude Code" })
	end,
}

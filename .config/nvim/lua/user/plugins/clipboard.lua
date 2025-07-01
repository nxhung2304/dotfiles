return {
	"ojroques/nvim-osc52",
	config = function()
		require("osc52").setup({})

		vim.keymap.set("n", "<leader>cc", require("osc52").copy_operator, { expr = true })
		vim.keymap.set("v", "<leader>cc", require("osc52").copy_visual)
	end,
}

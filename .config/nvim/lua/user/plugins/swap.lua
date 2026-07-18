-- Swap items in a comma-separated list (e.g. "a, b" -> "b, a")
-- Put cursor on an item, then cn swaps with next item, cp swaps with previous
return {
	"machakann/vim-swap",
	event = "VeryLazy",
	init = function()
		vim.g.swap_no_default_key_mappings = 1
	end,
	config = function()
		vim.keymap.set("n", "<leader>cn", "<Plug>(swap-next)", { desc = "Swap item with next" })
		vim.keymap.set("n", "<leader>cp", "<Plug>(swap-prev)", { desc = "Swap item with previous" })
	end,
}

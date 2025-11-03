return {
	{
		"tpope/vim-rails",
		ft = { "ruby", "yaml", "erb" },
		config = function()
			local utils = require("user.core.utils")
			local keymap = utils.keymap

			keymap("n", "<leader>rc", ":Vcontroller", { desc = "Open Controller" })
			keymap("n", "<leader>rm", ":Vmodel", { desc = "Open Model" })
			keymap("n", "<leader>rv", ":Vview<CR>", { desc = "Open View" })
		end,
	},
}

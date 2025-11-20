return {
	{
		"tpope/vim-rails",
    ft = { "ruby", "yaml", "erb" },
		keys = {
			{ "<leader>rc", "<cmd>Vcontroller", desc = "Open Controller" },
			{ "<leader>rm", "<cmd>Vmodel", desc = "Open Model" },
			{ "<leader>rv", "<cmd>Vview<cr>", desc = "Open View" },
			{ "<leader>ru", "<cmd>Vunittest<cr>", desc = "Open Unittest" },
			{ "<leader>rf", "<cmd>Vfixture<cr>", desc = "Open Fixture" },
		},
	},
}

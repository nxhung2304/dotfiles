return {
	{
		"tpope/vim-rails",
		lazy = false,
		keys = {
			{ "<leader>rc", "<cmd>Vcontroller<cr>", desc = "Open Controller" },
			{ "<leader>rm", "<cmd>Vmodel<cr>", desc = "Open Model" },
			{ "<leader>rv", "<cmd>Vview<cr>", desc = "Open View" },
			{ "<leader>ru", "<cmd>Vunittest<cr>", desc = "Open Unittest" },
			{ "<leader>rf", "<cmd>Vfixture<cr>", desc = "Open Fixture" },
			{ "<leader>rh", "<cmd>Vhelper<cr>", desc = "Open Helper" },
			{ "<leader>rj", "<cmd>Vjob<cr>", desc = "Open Job" },
			{ "<leader>rM", "<cmd>Vmailer<cr>", desc = "Open Mailer" },
		},
	},
}

return {
	"stevearc/aerial.nvim",
	opts = {
		filter_kind = {
			"Class",
			"Constructor",
			"Enum",
			"Interface",
			"Module",
			"Method",
			-- "Struct",
		},
	},
	keys = {
		{ "<leader>a", "<cmd>AerialToggle<CR>", desc = "Toggle Aerial" },
	},
}

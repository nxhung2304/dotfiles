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
		autojump = true,
		highlight_on_hover = true,
		highlight_on_jump = 250,
		highlight = {
			aerial_current = "Visual",
			aerial_guide = "Comment",
		},
	},
	keys = {
		{ "<leader>a", "<cmd>AerialToggle<CR>", desc = "Toggle Aerial" },
	},
}

return {
	"rmagatti/goto-preview",
	dependencies = { "rmagatti/logger.nvim" },
	event = "BufEnter",
	config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
	opts = {
		default_mappings = true, -- gpd/gpt/gpi/gpD/gpr open previews, gP closes all preview windows
		references = {
			provider = "snacks", -- this config uses snacks.nvim, not telescope, for pickers
		},
	},
}

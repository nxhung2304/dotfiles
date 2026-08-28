return {
	"nxhung2304/restman.nvim",
	config = function()
		require("restman").setup({
			keymaps = {
				send = "<leader>rs",
				repeat_last = "<leader>rr",
				env = "<leader>re",
				history = "<leader>rh",
				cancel = "<leader>rc",
			},
			response_view = {
				default_view = "float", -- "float" | "split" | "vsplit" | "tab"
				float = {
					relative = "editor",
					width = 0.8, -- 80% of editor width
					height = 0.7, -- 70% of editor height
					border = "rounded",
				},
				split = {
					position = "right",
					size = 80, -- column width
				},
			},
			timeout = 30, -- request timeout in seconds
			history = {
				enabled = true,
				max_entries = 100,
				deduplicate = true, -- keep only latest entry per file:line (set false to keep full timeline)
			},
		})
	end,
}

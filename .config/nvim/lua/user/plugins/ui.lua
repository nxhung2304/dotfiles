return {
	"stevearc/dressing.nvim",
	event = "VeryLazy",
	opts = {
		input = {
			enabled = true,
			border = "rounded", -- Border đẹp
			min_width = 60,
			get_config = function()
				if vim.api.nvim_get_option_value("modifiable", { buf = 0 }) then
					return { border = "single" } -- Customize per type
				end
			end,
		},
	},
}

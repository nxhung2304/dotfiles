local M = {}

function M.setup(config)
	config.color_scheme = "GruvboxDark"
	-- config.color_scheme = "Solarized (dark) (terminal.sexy)"

	-- config.window_decorations = "NONE"
	config.window_decorations = "RESIZE | TITLE"

	config.enable_tab_bar = false

	config.inactive_pane_hsb = {
		saturation = 0.9,
		brightness = 0.8,
	}

	config.window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	}
end

return M

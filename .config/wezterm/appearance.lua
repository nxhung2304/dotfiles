local M = {}

function M.setup(config)
	config.color_scheme = "GruvboxDark"
  -- config.color_scheme = 'Gruvbox Material (Gogh)'
	-- config.color_scheme = "Solarized (dark) (terminal.sexy)"

	-- config.window_decorations = "NONE"
	config.window_decorations = "RESIZE | TITLE"

	config.window_background_opacity = 0.9

	config.enable_tab_bar = false

	config.inactive_pane_hsb = {
		saturation = 0.9,
		brightness = 0.8,
	}

	config.window_padding = {
		left = 10,
		right = 10,
		top = 10,
		bottom = 10,
	}
end

return M

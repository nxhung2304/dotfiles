local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Appearance
config.color_scheme = "GruvboxDark"
config.window_decorations = "RESIZE | TITLE"

config.window_background_opacity = 1

config.enable_tab_bar = false

config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.8,
}

config.window_padding = {
	left = 5,
	right = 5,
	top = 5,
	bottom = 5,
}

-- Font
config.font = wezterm.font("JetBrainsMonoNL Nerd Font")
config.font_size = 13.5
config.line_height = 1.4

-- Scroll
config.scrollback_lines = 5000

-- Keys
config.keys = {
	-- Toggle full screen
	{
		key = "Enter",
		mods = "CMD",
		action = wezterm.action.ToggleFullScreen,
	},

	-- Word movement
	{
		key = "LeftArrow",
		mods = "ALT",
		action = wezterm.action.SendKey({
			key = "b",
			mods = "ALT",
		}),
	},
	{
		key = "RightArrow",
		mods = "ALT",
		action = wezterm.action.SendKey({
			key = "f",
			mods = "ALT",
		}),
	},

	-- Line movement
	{
		key = "LeftArrow",
		mods = "CMD",
		action = wezterm.action.SendKey({
			key = "a",
			mods = "CTRL",
		}),
	},
	{
		key = "RightArrow",
		mods = "CMD",
		action = wezterm.action.SendKey({
			key = "e",
			mods = "CTRL",
		}),
	},

	{
		key = "f",
		mods = "CMD",
		action = wezterm.action.Search({ CaseInSensitiveString = "" }),
	},

	-- Clear screen
	{
		key = "k",
		mods = "CMD",
		action = wezterm.action.ClearScrollback("ScrollbackAndViewport"),
	},

	-- Font size
	{
		key = "=",
		mods = "CMD",
		action = wezterm.action.IncreaseFontSize,
	},
	{
		key = "-",
		mods = "CMD",
		action = wezterm.action.DecreaseFontSize,
	},
	{
		key = "0",
		mods = "CMD",
		action = wezterm.action.ResetFontSize,
	},
}

return config

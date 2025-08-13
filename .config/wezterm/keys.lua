local wezterm = require("wezterm")
local M = {}

M.keys = {
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

function M.setup(config)
	config.keys = M.keys
end

return M

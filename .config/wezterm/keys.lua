local wezterm = require("wezterm")
local M = {}

M.keys = {
	{
		key = "Enter",
		mods = "CMD",
		action = wezterm.action.ToggleFullScreen,
	},
}

function M.setup(config)
	config.keys = M.keys
end

return M

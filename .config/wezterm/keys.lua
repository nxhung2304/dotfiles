local wezterm = require("wezterm")
local M = {}

M.keys = {
	{
		key = "Enter",
		mods = "CMD",
		action = wezterm.action.ToggleFullScreen,
	},
	{
		key = 'f',
		mods = 'CTRL|SHIFT',
		action = wezterm.action.SpawnCommandInNewTab {
			args = { '~/.local/bin/scripts/tmux-sessionizer' },
		},
	},
}

function M.setup(config)
	config.keys = M.keys
end

return M

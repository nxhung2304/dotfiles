local M = {}
local wezterm = require("wezterm")

function M.setup(config)
	config.font = wezterm.font("JetBrainsMonoNL Nerd Font")
	config.font_size = 14.4
	config.line_height = 1.4
end

return M

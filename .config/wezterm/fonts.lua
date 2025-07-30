local M = {}
local wezterm = require("wezterm")

function M.setup(config)
	config.font = wezterm.font("JetBrainsMonoNL Nerd Font")
	config.font_size = 12.5
	config.line_height = 1.2
end

return M

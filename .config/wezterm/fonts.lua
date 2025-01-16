local M = {}
local wezterm = require("wezterm")

function M.setup(config)
	config.font = wezterm.font("JetBrainsMonoNL Nerd Font Mono")
	config.font_size = 13
	config.line_height = 1.4
end

return M

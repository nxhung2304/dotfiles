local wezterm = require("wezterm")
local keys = require("keys")
local fonts = require("fonts")
local appearance = require("appearance")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

keys.setup(config)
fonts.setup(config)
appearance.setup(config)

return config

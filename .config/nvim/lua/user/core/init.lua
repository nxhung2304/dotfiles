require "user.core.custom_command"
require "user.core.keymaps"
require "user.core.options"
require "user.core.autocmds"

-- Load sidebar panels so they register themselves at startup
local sidebar = require "user.core.sidebar"
require "user.core.sidebar.search"
require "user.core.sidebar.marks"
sidebar.setup_keymaps()

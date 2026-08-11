-- No plugin dependency: the generic test runner (runner.lua) is a plain Lua
-- module loaded on demand by the keymaps in user/core/keymaps.lua. This file
-- exists so Lazy's `import = "user.plugins"` sees a valid (empty) spec here.
return {}

local util = require 'lspconfig.util'
local root_pattern = util.root_pattern('Package.swift', 'buildServer.json', 'compile_commands.json', '.git')

return {
  root_dir = function(bufnr, on_dir)
    on_dir(root_pattern(vim.api.nvim_buf_get_name(bufnr)))
  end,
}

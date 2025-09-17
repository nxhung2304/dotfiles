-- ESLint Language Server configuration
return {
  settings = {
    eslint = {
      enable = true,
      format = true,
      lintTask = {
        enable = true,
      },
    },
  },
  on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  end,
}
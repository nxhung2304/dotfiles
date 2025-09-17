-- Vue Language Server configuration for Vue 3
return {
  on_attach = function(client, bufnr)
    -- Disable semantic tokens for Vue files to avoid conflicts
    if vim.bo[bufnr].filetype == 'vue' then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
  filetypes = { 'vue' },
}
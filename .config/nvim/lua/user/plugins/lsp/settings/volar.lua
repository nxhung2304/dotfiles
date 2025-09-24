-- Volar (Vue Language Server) configuration for Vue 3
return {
  on_attach = function(client, bufnr)
    -- Call the main lsp_on_attach to set up keymaps including 'ga'
    require("user.core.utils").lsp_on_attach(client, bufnr)
    
    -- Disable semantic tokens for Vue files to avoid conflicts with TypeScript
    if vim.bo[bufnr].filetype == 'vue' then
      client.server_capabilities.semanticTokensProvider = nil
    end
    
    -- Ensure completion capability is enabled
    client.server_capabilities.completionProvider = {
      resolveProvider = true,
      triggerCharacters = { '.', ':', '<', '"', "'", '/', '@', '*' },
    }
  end,
  filetypes = { 'vue' },
  init_options = {
    vue = {
      hybridMode = false,
    },
  },
}

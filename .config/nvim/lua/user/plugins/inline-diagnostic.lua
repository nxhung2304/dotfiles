return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy", -- Or `LspAttach`
  priority = 1000,    -- needs to be loaded in first
  config = function()
    require('tiny-inline-diagnostic').setup({
      preset = "modern",
      options = {
        multilines = {
          -- Enable multiline diagnostic messages
          enabled = true,
          -- Always show messages on all lines for multiline diagnostics
          always_show = true,
          -- Trim whitespaces from the start/end of each line
          trim_whitespaces = false,

          tabstop = 4,
        },
      }
    })
    vim.diagnostic.config({ virtual_text = false })
  end
}

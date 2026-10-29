return {
  "luckasRanarison/tailwind-tools.nvim",
  ft = {
    "css", "eruby", "html"
  },
  keys = {
    { "<leader>ct", "<cmd>TailwindColorToggle<cr>", desc = "Toggle Tailwind color highlight" },
  },
  opts = {
    document_color = {
      enabled = false, -- toggle at runtime with <leader>ct
      kind = "background", -- "background" | "foreground" | "inline"
      inline_symbol = "󰝤 ",
      debounce = 200,
    },
    server = {
      override = false,
      enabled = false,
    },
  },
}

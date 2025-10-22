require("user.core.bootstrap_lazy")

require("lazy").setup({
  spec = {
    { import = "user.plugins" },
  },
  change_detection = { enabled = false },
})

require("user.core")

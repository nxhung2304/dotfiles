return {
  "pocco81/auto-save.nvim",
  event = "InsertEnter",
  opts = {
    enabled = true,
    execution_message = {
      message = function() -- message to print on save
        return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
      end,
      dim = 0.18,           -- dim the color of `message`
      cleaning_interval = 2000, -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
    },
  }
}

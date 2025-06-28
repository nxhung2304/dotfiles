# Event execution order
```
Opening a file:
BufNewFile/BufReadPre → BufRead → FileType → BufEnter → WinEnter
(tạo/chuẩn bị)    (đọc file)  (nhận diện)  (vào buffer) (focus window)

Saving a file:  
BufWritePre → BufWrite → BufWritePost
(chuẩn bị ghi)  (đang ghi)   (hoàn thành)

Switching buffers:
BufLeave → WinLeave → BufEnter → WinEnter  
(rời buffer) (rời window) (vào buffer mới) (focus window mới)

```

# All events
## Buffer Events
### BufNewFile
```
lua-- Kích hoạt khi tạo file mới (chưa tồn tại)
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.dart",
  callback = function()
    print("Creating new Dart file!")
  end,
})
```

### BufRead/BufReadPre/BufReadPost
```
lua-- BufReadPre: Trước khi đọc file vào buffer
vim.api.nvim_create_autocmd("BufReadPre", {
  pattern = "*",
  callback = function()
    print("About to read file...")
  end,
})

-- BufRead/BufReadPost: Sau khi đọc file thành công
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*.json",
  callback = function()
    vim.cmd("set filetype=json")
  end,
})
```

### BufWrite/BufWritePre/BufWritePost
```
lua-- BufWritePre: Trước khi save file
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.dart",
  callback = function()
    -- Auto format trước khi save
    vim.lsp.buf.format()
  end,
})

-- BufWritePost: Sau khi save thành công
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "pubspec.yaml",
  callback = function()
    vim.cmd("LspRestart") -- Restart LSP khi pubspec thay đổi
  end,
})
```

### BufEnter/BufLeave
```
lua-- BufEnter: Khi switch vào buffer
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.dart",
  callback = function()
    print("Switched to Dart file")
  end,
})

-- BufLeave: Khi rời khỏi buffer
vim.api.nvim_create_autocmd("BufLeave", {
  callback = function()
    -- Save session trước khi leave
    vim.cmd("mksession! ~/.local/state/nvim/session.vim")
  end,
})
```

### BufDelete/BufWipeout
```
lua-- BufDelete: Khi delete buffer (file vẫn còn)
-- BufWipeout: Khi wipeout buffer hoàn toàn
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function()
    print("Buffer deleted")
  end,
})
```

## Window Events
### WinEnter/WinLeave
```
lua-- WinEnter: Khi focus vào window
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    vim.wo.relativenumber = true -- Enable relative numbers
  end,
})

-- WinLeave: Khi rời window
vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    vim.wo.relativenumber = false -- Disable relative numbers
  end,
})
```

### WinNew/WinClosed
```
lua-- WinNew: Khi tạo window mới
vim.api.nvim_create_autocmd("WinNew", {
  callback = function()
    print("New window created")
  end,
})
```

## File Type Events
### FileType
```
lua-- Khi filetype được detect/set
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dart",
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.expandtab = true
  end,
})

-- Multiple filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"javascript", "typescript", "dart"},
  callback = function()
    vim.bo.tabstop = 2
  end,
})

```

## LSP Events
### LspAttach/LspDetach
```
lua-- Khi LSP attach vào buffer
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    print("LSP attached: " .. client.name)
    
    -- Setup LSP keymaps
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf })
  end,
})

-- Khi LSP detach
vim.api.nvim_create_autocmd("LspDetach", {
  callback = function(args)
    print("LSP detached")
  end,
})
```

## UI Events
### VimEnter/VimLeave
```
lua-- VimEnter: Khi Neovim khởi động xong
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    print("Welcome to Neovim!")
    -- Auto open NvimTree
    vim.cmd("NvimTreeOpen")
  end,
})

-- VimLeave: Trước khi thoát Neovim
vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    -- Cleanup, save session
    print("Goodbye!")
  end,
})
```

## ColorScheme
```
lua-- Khi colorscheme thay đổi
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    -- Custom highlights
    vim.cmd("highlight MyCustomGroup guifg=#ff0000")
  end,
})
```

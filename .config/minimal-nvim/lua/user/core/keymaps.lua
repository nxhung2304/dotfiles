local keymap = function(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }

	if opts then
		options = vim.tbl_extend("force", options, opts)
	end

	vim.keymap.set(mode, lhs, rhs, options)
end

keymap("n", "<C-s>", "<cmd>:w!<cr>", { desc = "Save file" })
keymap("i", "<C-s>", "<cmd>:w!<cr>", { desc = "Save file" })

keymap("n", "<C-h>", "<C-w>h")
keymap("n", "<C-j>", "<C-w>j")
keymap("n", "<C-k>", "<C-w>k")
keymap("n", "<C-l>", "<C-w>l")

keymap("v", "y", "ygv<Esc>", { desc = "Yank and hold current cursor" })

keymap("i", "jk", "<ESC>")

keymap("v", "p", '"_dP')

keymap("x", "J", ":move '>+1<CR>gv-gv", { desc = "Move current line to down" })
keymap("x", "K", ":move '<-2<CR>gv-gv", { desc = "Move current line to up" })

keymap("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>")

keymap("n", "<leader>ca", "<cmd>CopyAbsolutePath<cr>", { desc = "Copy absolute filepath" })
keymap("n", "<leader>cr", "<cmd>CoppyRelativePath<cr>", { desc = "Copy relative filepath" })

keymap("t", "<Esc>", "<C-\\><C-n>")

keymap("v", ">", ">gv", { desc = "Indent in" })
keymap("v", "<", "<gv", { desc = "Indent out" })

vim.keymap.set("n", "<leader>cd", "<cmd>CopyCurrentDiagnostic<cr>", { desc = "Copy current diagnostic" })

-- Diagnostics
keymap("n", "]e", function()
	vim.diagnostic.goto_next({
		severity = vim.diagnostic.severity.ERROR,
		float = { border = "rounded" },
	})
end)

keymap("n", "[e", function()
	vim.diagnostic.goto_prev({
		severity = vim.diagnostic.severity.ERROR,
		float = { border = "rounded" },
	})
end)

-- Quickfix
keymap("n", "]q", ":cnext<CR>", { desc = "Next quickfix item" })
keymap("n", "[q", ":cprev<CR>", { desc = "Previous quickfix item" })

-- UI
keymap("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Disable hlsearch" })

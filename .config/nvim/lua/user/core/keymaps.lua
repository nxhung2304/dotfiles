local utils = require("user.core.utils")
local keymap = utils.keymap

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

keymap(
	"n",
	"<C-f>",
	"<cmd>silent !tmux neww '~/.local/bin/scripts/tmux-sessionizer'<CR>",
	{ desc = "Find folders in ~/Dev" }
)

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

vim.keymap.set("n", "<leader>ud", function()
	local qf_winid = vim.fn.getqflist({ winid = 0 }).winid

	if qf_winid ~= 0 then
		vim.cmd("cclose")
	else
		utils.open_sorted_diagnostics()
	end
end, { desc = "Toggle sorted diagnostics" })

vim.api.nvim_create_autocmd("BufWritePost", {
	callback = function()
		local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
		if qf_winid ~= 0 then
			local current_win = vim.api.nvim_get_current_win()

			vim.defer_fn(function()
				utils.open_sorted_diagnostics()
			end, 50)

			pcall(function()
				vim.api.nvim_set_current_win(current_win)
			end)
		end
	end,
})

keymap("n", "<leader>um", "<cmd>NoiceAll<cr>", { desc = "Show messages" })


vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

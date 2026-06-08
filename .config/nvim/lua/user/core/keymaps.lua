local utils = require("user.core.utils")
local keymap = utils.keymap

keymap("n", "<C-s>", "<cmd>:w!<cr>", { desc = "Save file" })
keymap("i", "<C-s>", "<cmd>:w!<cr>", { desc = "Save file" })

-- Clipboard via OSC52
-- keymap("n", "<leader>cc", '"+y', { desc = "Copy to clipboard (OSC52)" })
-- keymap("v", "<leader>cc", '"+y', { desc = "Copy selection to clipboard (OSC52)" })

keymap("n", "<C-h>", "<C-w>h")
keymap("n", "<C-j>", "<C-w>j")
keymap("n", "<C-k>", "<C-w>k")
keymap("n", "<C-l>", "<C-w>l")

keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "<C-d>", "<C-d>zz")

keymap("v", "y", "ygv<Esc>", { desc = "Yank and hold current cursor" })

keymap("i", "jk", "<ESC>")

keymap("v", "p", '"_dP')

keymap("x", "J", ":move '>+1<CR>gv-gv", { desc = "Move current line to down" })
keymap("x", "K", ":move '<-2<CR>gv-gv", { desc = "Move current line to up" })

keymap("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>")

keymap("n", "<leader>cs", function()
	local word = vim.fn.expand("<cword>")
	vim.api.nvim_feedkeys(":%s/" .. vim.fn.escape(word, "/") .. "/", "n", false)
end, { desc = "Substitute in file" })

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

-- Restart
keymap("n", "<leader>uR", function()
	local file = vim.fn.expand("%:p")
	if file ~= "" then
		vim.fn.writefile({ file }, vim.fn.stdpath("cache") .. "/restart_file")
	end
	vim.cmd("silent! wall")
	vim.cmd("restart")
end, { desc = "Restart Neovim and reopen last file" })

-- Macro
keymap("n", "Q", "@q", { desc = "Replay macro @q" })
keymap("x", "Q", ":norm @q<CR>", { desc = "Replay macro on selection" })
keymap("n", "<leader>q", "@@", { desc = "Replay last macro" })

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

vim.keymap.set("t", "jk", [[<C-\><C-n>]])
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])

-- Claude Code integration
local function find_claude_pane()
	local result = vim.fn.systemlist("tmux list-panes -s -F '#{window_id} #{pane_id} #{pane_current_command}' 2>/dev/null")
	for _, line in ipairs(result) do
		if line:lower():match("claude") then
			local win, pane = line:match("^(%S+)%s+(%S+)")
			return win, pane
		end
	end
end

local function send_to_claude(ref)
	if vim.fn.exists("$TMUX") == 0 then
		vim.notify("Not inside a tmux session", vim.log.levels.WARN)
		return
	end

	local function do_send(win, pane)
		vim.fn.system(string.format("tmux send-keys -t %s -l %s", pane, vim.fn.shellescape(ref)))
		vim.fn.system(string.format("tmux send-keys -t %s -l '\\'", pane))
		vim.fn.system(string.format("tmux send-keys -t %s Enter", pane))
		vim.fn.system(string.format("tmux select-window -t %s", win))
		vim.fn.system(string.format("tmux select-pane -t %s", pane))
	end

	local win, pane = find_claude_pane()
	if pane then
		do_send(win, pane)
	else
		vim.fn.system("tmux new-window 'claude'")
		vim.defer_fn(function()
			win, pane = find_claude_pane()
			if pane then
				do_send(win, pane)
			else
				vim.notify("Could not find Claude Code pane after launch", vim.log.levels.WARN)
			end
		end, 3500)
	end
end

keymap("n", "<leader>ac", function()
	local lnum = vim.fn.line(".")
	local rel = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:.")
	send_to_claude(string.format("@%s:%d", rel, lnum))
end, { desc = "Send current line ref to Claude Code" })

vim.keymap.set("x", "<leader>cc", function()
	local anchor = vim.fn.getpos("v")[2]
	local cursor = vim.fn.getpos(".")[2]
	local s = math.min(anchor, cursor)
	local e = math.max(anchor, cursor)
	local rel = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:.")
	send_to_claude(string.format("@%s:%d-%d", rel, s, e))
end, { noremap = true, silent = true, desc = "Send selection ref to Claude Code" })

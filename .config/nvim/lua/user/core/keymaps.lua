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
keymap("t", "<C-w>h", [[<C-\><C-n><C-w>h]])
keymap("t", "<C-w>j", [[<C-\><C-n><C-w>j]])
keymap("t", "<C-w>k", [[<C-\><C-n><C-w>k]])
keymap("t", "<C-w>l", [[<C-\><C-n><C-w>l]])
keymap("t", "jk", [[<C-\><C-n>]])

keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "<C-d>", "<C-d>zz")

keymap("v", "y", "ygv<Esc>", { desc = "Yank and hold current cursor" })

keymap("i", "jk", "<ESC>")

keymap("v", "p", '"_dP')

keymap("x", "J", ":move '>+1<CR>gv-gv", { desc = "Move current line to down" })
keymap("x", "K", ":move '<-2<CR>gv-gv", { desc = "Move current line to up" })

keymap("n", "ga", function()
	local ruby_fts = { ruby = true, eruby = true, haml = true, slim = true }
	if ruby_fts[vim.bo.filetype] then
		-- Delegate to rails.lua's ga_code_action via user event
		vim.api.nvim_exec_autocmds("User", { pattern = "RailsCodeAction" })
		return
	end
	local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/codeAction" })
	if #clients > 0 then vim.lsp.buf.code_action() end
end)

keymap("n", "<leader>cs", function()
	local word = vim.fn.expand("<cword>")
	return ":%s/" .. vim.fn.escape(word, "/\\") .. "/"
end, { expr = true, desc = "Substitute in file" })

keymap("n", "<leader>ya", "<cmd>CopyAbsolutePath<cr>", { desc = "Copy absolute filepath" })
keymap("n", "<leader>yr", "<cmd>CoppyRelativePath<cr>", { desc = "Copy relative filepath" })

keymap("t", "<Esc>", "<C-\\><C-n>")

keymap("v", ">", ">gv", { desc = "Indent in" })
keymap("v", "<", "<gv", { desc = "Indent out" })

vim.keymap.set("n", "<leader>yd", "<cmd>CopyCurrentDiagnostic<cr>", { desc = "Copy current diagnostic" })

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
local function herdr_json(args)
	local output = vim.fn.system(vim.list_extend({ "herdr" }, args))
	if vim.v.shell_error ~= 0 then
		return nil
	end
	local ok, decoded = pcall(vim.json.decode, output)
	return ok and decoded or nil
end

local function find_claude_pane()
	local listing = herdr_json({ "pane", "list" })
	if not listing then
		return nil
	end
	local current_workspace_id
	for _, pane in ipairs(listing.result.panes) do
		if pane.pane_id == vim.env.HERDR_PANE_ID then
			current_workspace_id = pane.workspace_id
		end
	end
	for _, pane in ipairs(listing.result.panes) do
		if pane.agent == "claude" and pane.workspace_id == current_workspace_id then
			return pane.tab_id, pane.pane_id
		end
	end
end

local function send_to_claude(lines)
	if not vim.env.HERDR_PANE_ID then
		vim.notify("Not inside a herdr session", vim.log.levels.WARN)
		return
	end

	local function do_send(tab_id, pane_id)
		for _, line in ipairs(lines) do
			vim.fn.system({ "herdr", "pane", "send-text", pane_id, line .. "\\" })
			vim.fn.system({ "herdr", "pane", "send-keys", pane_id, "enter" })
		end
		vim.fn.system({ "herdr", "tab", "focus", tab_id })
		vim.fn.system({ "herdr", "agent", "focus", pane_id })
	end

	local tab_id, pane_id = find_claude_pane()
	if pane_id then
		do_send(tab_id, pane_id)
		return
	end

	local current = herdr_json({ "pane", "current", "--current" })
	if not current then
		vim.notify("Could not read current herdr pane", vim.log.levels.WARN)
		return
	end
	local current_pane = current.result.pane
	local created = herdr_json({
		"tab", "create",
		"--workspace", current_pane.workspace_id,
		"--cwd", current_pane.cwd,
		"--label", "claude",
		"--focus",
	})
	if not created then
		vim.notify("Could not create herdr tab for Claude Code", vim.log.levels.WARN)
		return
	end
	local root_pane_id = created.result.root_pane.pane_id
	vim.fn.system({ "herdr", "pane", "run", root_pane_id, "claude" })
	vim.defer_fn(function()
		do_send(created.result.tab.tab_id, root_pane_id)
	end, 3500)
end

keymap("n", "<leader>cc", function()
	local lnum = vim.fn.line(".")
	local rel = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:.")
	send_to_claude({ string.format("%s:%d", rel, lnum) })
end, { desc = "Send current line ref to Claude Code" })

vim.keymap.set("x", "<leader>cc", function()
	local anchor = vim.fn.getpos("v")[2]
	local cursor = vim.fn.getpos(".")[2]
	local s = math.min(anchor, cursor)
	local e = math.max(anchor, cursor)
	local rel = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:.")
	local selected_lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
	local lines = { string.format("%s:%d-%d", rel, s, e), "```" }
	vim.list_extend(lines, selected_lines)
	table.insert(lines, "```")
	send_to_claude(lines)
end, { noremap = true, silent = true, desc = "Send selection ref to Claude Code" })

-- Generic test runner (framework detected per buffer/project — see
-- user/plugins/test/). Loaded lazily on first use.
local function test()
	return require("user.plugins.test.runner")
end

keymap("n", "<leader>tc", function()
	test().run_nearest()
end, { desc = "Test at Cursor" })
keymap("n", "<leader>tf", function()
	test().run_file()
end, { desc = "Test File" })
keymap("n", "<leader>ta", function()
	test().run_all()
end, { desc = "Test All" })
keymap("n", "<leader>tl", function()
	test().run_last()
end, { desc = "Rerun Last Test" })
keymap("n", "<leader>tt", function()
	test().toggle_test_panel()
end, { desc = "Toggle Test Panel" })
keymap("n", "<leader>to", function()
	test().focus_test_output()
end, { desc = "Focus Test Output" })
keymap("n", "]f", function()
	test().goto_failure(1)
end, { desc = "Next test failure" })
keymap("n", "[f", function()
	test().goto_failure(-1)
end, { desc = "Prev test failure" })

local saved_zen_state = nil
keymap("n", "<leader>uz", function()
	if saved_zen_state then
		vim.o.laststatus = saved_zen_state.laststatus
		vim.o.winbar = saved_zen_state.global_winbar
		for window, winbar in pairs(saved_zen_state.winbars) do
			if vim.api.nvim_win_is_valid(window) then
				vim.wo[window].winbar = winbar
			end
		end
		saved_zen_state = nil
		return
	end
	saved_zen_state = { laststatus = vim.o.laststatus, global_winbar = vim.o.winbar, winbars = {} }
	for _, window in ipairs(vim.api.nvim_list_wins()) do
		saved_zen_state.winbars[window] = vim.wo[window].winbar
		vim.wo[window].winbar = ""
	end
	vim.o.laststatus = 0
	vim.o.winbar = ""
end, { desc = "Zen mode (hide statusline + winbar)" })

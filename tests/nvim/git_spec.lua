local plugins_dir = vim.env.TEST_PLUGINS_DIR
local repo_dir = vim.env.TEST_REPO_DIR
local test_case = vim.env.TEST_CASE

vim.opt.rtp:prepend(plugins_dir .. "/neogit")
vim.opt.rtp:prepend(plugins_dir .. "/diffbandit.nvim")
vim.cmd("runtime plugin/neogit.lua")
vim.cmd("runtime plugin/diffbandit.lua")
package.loaded["user.core.utils"] = { keymap = function() end, confirm = function() end }

local specs = dofile(repo_dir .. "/.config/nvim/lua/user/plugins/git.lua")
local specs_by_name = {}
for _, spec in ipairs(specs) do
	specs_by_name[spec[1]] = spec
end
local neogit_spec = specs_by_name["NeogitOrg/neogit"]
local diffbandit_spec = specs_by_name["CoreyKaylor/diffbandit.nvim"]
require("diffbandit").setup(diffbandit_spec.opts)
require("neogit").setup(neogit_spec.opts)

local OPEN_TIMEOUT_MS = 3000
local POPUP_TIMEOUT_MS = 1500
local POLL_INTERVAL_MS = 50
local SETTLE_MS = 300
local STATUS_RENDER_MS = 800
local NOTIFY_SETTLE_MS = 500
local CHANGED_FILE_PATTERN = "hello%.txt"
local COMMIT_LINE_PATTERN = "^%x%x%x%x%x%x%x "

local error_messages = {}
vim.notify = function(message, level)
	if level == vim.log.levels.ERROR or level == vim.log.levels.WARN then
		error_messages[#error_messages + 1] = message
	end
end

local failure_count = 0

local function check(description, is_ok, detail)
	if is_ok then
		io.stdout:write("  PASS " .. description .. "\n")
	else
		io.stdout:write("  FAIL " .. description .. ": " .. tostring(detail) .. "\n")
		failure_count = failure_count + 1
	end
end

local function find_key_action(key_sequence)
	for _, key in ipairs(diffbandit_spec.keys) do
		if key[1] == key_sequence then
			return key[2]
		end
	end
end

local function wait_for_new_tab()
	vim.wait(OPEN_TIMEOUT_MS, function()
		return #vim.api.nvim_list_tabpages() > 1 or #error_messages > 0
	end, POLL_INTERVAL_MS)
	vim.wait(SETTLE_MS)
end

local function collect_visible_buffers()
	local buffers = {}
	for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buffer = vim.api.nvim_win_get_buf(window)
		local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buffer), ":t")
		if name ~= "" then
			buffers[name] = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
		end
	end

	return buffers
end

local function buffer_contains(buffers, name, text)
	return buffers[name] ~= nil and buffers[name]:find(text) ~= nil
end

local function command_from_key_action(key_action)
	local command = key_action:gsub("^<cmd>", "")
	command = command:gsub("<cr>$", "")

	return command
end

local function open_neogit_on(line_pattern)
	vim.cmd("silent! DiffBanditClose")
	vim.cmd("silent! tabonly")
	require("neogit").open({ kind = "replace" })
	vim.wait(OPEN_TIMEOUT_MS, function()
		return vim.bo.filetype == "NeogitStatus"
	end, POLL_INTERVAL_MS)
	vim.wait(STATUS_RENDER_MS)
	for line_number, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
		if line:match(line_pattern) then
			vim.api.nvim_win_set_cursor(0, { line_number, 0 })
			break
		end
	end
end

local function press_in_diff_popup(key)
	vim.api.nvim_feedkeys("d", "x", false)
	vim.wait(POPUP_TIMEOUT_MS, function()
		return vim.bo.filetype == "NeogitPopup"
	end, POLL_INTERVAL_MS)
	local popup_text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	vim.api.nvim_feedkeys(key, "x", false)
	wait_for_new_tab()

	return popup_text
end

local cases = {}

function cases.neogit_popup()
	open_neogit_on(CHANGED_FILE_PATTERN)
	local popup_text = press_in_diff_popup("D")
	local file_buffers = collect_visible_buffers()
	check("popup shows the DiffBandit column", popup_text:find("DiffBandit") ~= nil, popup_text)
	check("D on a file opens that file", file_buffers["hello.txt"] ~= nil, vim.inspect(file_buffers))

	open_neogit_on(COMMIT_LINE_PATTERN)
	press_in_diff_popup("D")
	local commit_buffers = collect_visible_buffers()
	local has_commit_review = false
	for name in pairs(commit_buffers) do
		if name:match("^diffbandit%-commit") then
			has_commit_review = true
		end
	end
	check("D on a commit opens the commit review", has_commit_review, vim.inspect(commit_buffers))

	for _, key in ipairs({ "W", "S", "B", "L" }) do
		local errors_before = #error_messages
		open_neogit_on(CHANGED_FILE_PATTERN)
		press_in_diff_popup(key)
		check(key .. " opens without errors", #error_messages == errors_before, error_messages[#error_messages])
	end
end

function cases.review_branch()
	find_key_action("<leader>gB")()
	wait_for_new_tab()
	local buffers = collect_visible_buffers()
	local fork_point_side
	for name, content in pairs(buffers) do
		if name:match("^f %(") then
			fork_point_side = content
		end
	end
	check("left side is the fork point", fork_point_side ~= nil, vim.inspect(buffers))
	check(
		"commits added to develop later are not shown",
		fork_point_side and not fork_point_side:find("develop_after_branch"),
		fork_point_side
	)
end

function cases.no_base_branch()
	find_key_action("<leader>gB")()
	vim.wait(NOTIFY_SETTLE_MS)
	local has_warning = error_messages[1] == "No develop, main or master branch found"
	check("warns when no base branch exists", has_warning, error_messages[1])
end

function cases.merge_conflict()
	vim.cmd("edit f")
	vim.cmd(command_from_key_action(find_key_action("<leader>gm")))
	wait_for_new_tab()
	local buffers = collect_visible_buffers()
	check("merge view shows our side", buffer_contains(buffers, "f (local)", "OURS"), vim.inspect(buffers))
	check("merge view shows their side", buffer_contains(buffers, "f (remote)", "THEIRS"), vim.inspect(buffers))
end

cases[test_case]()
vim.cmd(failure_count == 0 and "qa!" or "cq!")

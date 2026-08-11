-- Generic terminal test runner. Frameworks are described by adapters (see
-- adapters.lua); this module owns the UI: a right-hand terminal split with a
-- spinner/pass/fail winbar, jump-to-error, and failure navigation.

local adapters = require("user.plugins.test.adapters")

local M = {}

local last_cmd = nil
local last_adapter = nil
local last_label = nil
local current_adapter = nil
local test_win_id = nil
local test_buf_id = nil
local spinner_timer = nil
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function ensure_hl()
	vim.api.nvim_set_hl(0, "TestRunning", { fg = "#fabd2f", bold = true })
	vim.api.nvim_set_hl(0, "TestPassed", { fg = "#b8bb26", bold = true })
	vim.api.nvim_set_hl(0, "TestFailed", { fg = "#fb4934", bold = true })
end
ensure_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = ensure_hl })

local function stop_spinner()
	if spinner_timer then
		spinner_timer:stop()
		spinner_timer:close()
		spinner_timer = nil
	end
end

local function start_spinner(win, label)
	stop_spinner()
	local idx = 1
	spinner_timer = vim.uv.new_timer()
	spinner_timer:start(
		0,
		100,
		vim.schedule_wrap(function()
			if not vim.api.nvim_win_is_valid(win) then
				stop_spinner()
				return
			end
			vim.wo[win].winbar = string.format("%%#TestRunning# %s %s%%*", spinner_frames[idx], label)
			idx = (idx % #spinner_frames) + 1
		end)
	)
end

local function set_winbar(win, status, label)
	if not vim.api.nvim_win_is_valid(win) then
		return
	end
	local hl = ({ pass = "TestPassed", fail = "TestFailed" })[status]
	local icon = ({ pass = "✓", fail = "✗" })[status]
	vim.wo[win].winbar = string.format("%%#%s# %s %s%%*", hl, icon, label)
end

-- Try each of the adapter's location patterns against a chunk of text.
local function match_location(adapter, chunk)
	for _, pat in ipairs(adapter.loc_patterns) do
		local file, lnum = chunk:match(pat)
		if file then
			return (file:gsub("%s+", "")), tonumber(lnum)
		end
	end
end

function M.run_test(cmd, adapter, label)
	last_cmd, last_adapter, last_label = cmd, adapter, label
	current_adapter = adapter
	label = label or "test"

	local origin_win = vim.api.nvim_get_current_win()

	local file_win = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if win ~= test_win_id then
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.api.nvim_get_option_value("buftype", { buf = buf }) ~= "terminal" then
				file_win = win
				break
			end
		end
	end
	file_win = file_win or origin_win

	if test_win_id and vim.api.nvim_win_is_valid(test_win_id) then
		vim.api.nvim_win_close(test_win_id, true)
	end
	if test_buf_id and vim.api.nvim_buf_is_valid(test_buf_id) then
		pcall(vim.api.nvim_buf_delete, test_buf_id, { force = true })
	end
	test_win_id = nil
	test_buf_id = nil

	vim.api.nvim_set_current_win(file_win)
	vim.cmd("botright vsplit")
	vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.38))
	test_win_id = vim.api.nvim_get_current_win()

	local term_buf = vim.api.nvim_create_buf(false, true)
	test_buf_id = term_buf
	vim.api.nvim_win_set_buf(test_win_id, term_buf)

	vim.keymap.set("n", "q", function()
		if test_win_id and vim.api.nvim_win_is_valid(test_win_id) then
			vim.api.nvim_win_close(test_win_id, true)
			test_win_id = nil
		end
	end, { buffer = term_buf, silent = true })

	local function jump_to_error_under_cursor()
		local buf = vim.api.nvim_win_get_buf(test_win_id)
		local cur = vim.api.nvim_win_get_cursor(test_win_id)[1]
		local total = vim.api.nvim_buf_line_count(buf)
		local chunk = table.concat(vim.api.nvim_buf_get_lines(buf, cur - 1, math.min(cur + 4, total), false), "\n")
		local file, lnum = match_location(adapter, chunk)
		if not file then
			return
		end
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if win ~= test_win_id then
				local wbuf = vim.api.nvim_win_get_buf(win)
				if vim.api.nvim_get_option_value("buftype", { buf = wbuf }) ~= "terminal" then
					vim.api.nvim_set_current_win(win)
					vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(file))
					return
				end
			end
		end
	end

	vim.keymap.set("n", "<CR>", jump_to_error_under_cursor, { buffer = term_buf, silent = true })
	vim.keymap.set("n", "gf", jump_to_error_under_cursor, { buffer = term_buf, silent = true })

	start_spinner(test_win_id, label)

	local started_at = vim.uv.hrtime()

	vim.fn.termopen(cmd, {
		on_exit = function(_, code)
			vim.schedule(function()
				stop_spinner()
				local buf = test_buf_id
				if not (buf and vim.api.nvim_buf_is_valid(buf)) then
					return
				end

				local elapsed = string.format("%.2fs", (vim.uv.hrtime() - started_at) / 1e9)
				local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
				local fail_count = adapter.summary(content)

				if code == 0 then
					if test_win_id and vim.api.nvim_win_is_valid(test_win_id) then
						set_winbar(test_win_id, "pass", label .. " (" .. elapsed .. ")")
					end
					vim.notify("✓ Passed — " .. label .. " (" .. elapsed .. ")", vim.log.levels.INFO)
					vim.fn.setqflist({}, "r")
					vim.defer_fn(function()
						if test_win_id and vim.api.nvim_win_is_valid(test_win_id) then
							vim.api.nvim_win_close(test_win_id, true)
							test_win_id = nil
						end
					end, 2000)
				else
					local n = fail_count or 0
					local summary = n > 0 and (n .. " failure" .. (n ~= 1 and "s" or "")) or "error"
					if test_win_id and vim.api.nvim_win_is_valid(test_win_id) then
						set_winbar(test_win_id, "fail", label .. " (" .. summary .. ", " .. elapsed .. ")")
						local line_count = vim.api.nvim_buf_line_count(buf)
						vim.api.nvim_win_set_cursor(test_win_id, { line_count, 0 })
					end
					vim.notify("✗ " .. summary .. " — " .. label .. " (" .. elapsed .. ")", vim.log.levels.WARN)
				end
			end)
		end,
	})

	vim.bo[term_buf].filetype = "terminal"
	vim.wo[test_win_id].number = false
	vim.wo[test_win_id].signcolumn = "no"

	vim.api.nvim_set_current_win(file_win)
end

--------------------------------------------------------------------------------
-- Dispatch: detect the framework for the current buffer/project and run.
--------------------------------------------------------------------------------
local function dispatch(kind)
	local adapter = adapters.pick()
	if not adapter then
		vim.notify("No test framework detected for this buffer/project", vim.log.levels.WARN)
		return
	end
	local cmd, label = adapter[kind]()
	M.run_test(cmd, adapter, label)
end

function M.run_nearest()
	dispatch("nearest")
end

function M.run_file()
	dispatch("file")
end

function M.run_all()
	dispatch("all")
end

function M.run_last()
	if last_cmd then
		M.run_test(last_cmd, last_adapter, last_label)
	else
		vim.notify("No previous test command", vim.log.levels.WARN)
	end
end

--------------------------------------------------------------------------------
-- Panel + failure navigation
--------------------------------------------------------------------------------
function M.toggle_test_panel()
	if test_win_id and vim.api.nvim_win_is_valid(test_win_id) then
		vim.api.nvim_win_close(test_win_id, true)
		test_win_id = nil
	elseif test_buf_id and vim.api.nvim_buf_is_valid(test_buf_id) then
		local origin_win = vim.api.nvim_get_current_win()
		vim.cmd("botright vsplit")
		vim.cmd("wincmd =")
		test_win_id = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(test_win_id, test_buf_id)
		vim.wo[test_win_id].number = false
		vim.wo[test_win_id].signcolumn = "no"
		local line_count = vim.api.nvim_buf_line_count(test_buf_id)
		vim.api.nvim_win_set_cursor(test_win_id, { line_count, 0 })
		vim.api.nvim_set_current_win(origin_win)
	else
		vim.notify("No test output available", vim.log.levels.WARN)
	end
end

function M.focus_test_output()
	if test_win_id and vim.api.nvim_win_is_valid(test_win_id) then
		vim.api.nvim_set_current_win(test_win_id)
	else
		vim.notify("No test output open", vim.log.levels.WARN)
	end
end

-- dir: 1 = next failure, -1 = previous failure
function M.goto_failure(dir)
	local win = test_win_id
	if not (win and vim.api.nvim_win_is_valid(win)) then
		vim.notify("No test output open", vim.log.levels.WARN)
		return
	end
	local markers = (current_adapter and current_adapter.failure_markers) or { "^Failure:", "^Error:" }
	local buf = vim.api.nvim_win_get_buf(win)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local cur = vim.api.nvim_win_get_cursor(win)[1]
	local from = cur + dir
	local to = dir > 0 and #lines or 1
	for i = from, to, dir do
		local line = lines[i]
		for _, m in ipairs(markers) do
			if line and line:match(m) then
				vim.api.nvim_set_current_win(win)
				vim.api.nvim_win_set_cursor(win, { i, 0 })
				return
			end
		end
	end
	vim.notify("No more failures", vim.log.levels.INFO)
end

return M

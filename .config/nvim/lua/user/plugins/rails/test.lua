local M = {}

local last_test_cmd = nil
local test_win_id = nil
local test_buf_id = nil
local spinner_timer = nil
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

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

local function parse_test_output(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	-- Join lines to handle terminal line-wrapping breaking paths across lines
	local content = table.concat(lines, "\n")
	local qflist = {}
	local fail_count = 0

	for file, lnum in content:gmatch("%[([^%]]+):(%d+)%]:") do
		file = file:gsub("\n", ""):gsub("%s+", "")
		if file ~= "" then
			table.insert(qflist, { filename = file, lnum = tonumber(lnum), text = "Test failure", type = "E" })
		end
	end

	local f, e = content:match("(%d+) failures?, (%d+) errors?")
	fail_count = f and (tonumber(f) + tonumber(e)) or #qflist

	return qflist, fail_count
end

function M.run_test(cmd)
	last_test_cmd = cmd

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
		local file, lnum = chunk:match("%[([^%]]+):(%d+)%]:")
		if not file then
			return
		end
		file = file:gsub("\n", ""):gsub("%s+", "")
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

	local label = cmd:match("bundle exec rails test (.+)$") or "rails test"
	label = vim.fn.fnamemodify(label:gsub(":%d+$", ""), ":.")
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
				local _, fail_count = parse_test_output(buf)

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
					local summary = fail_count > 0 and (fail_count .. " failure" .. (fail_count ~= 1 and "s" or ""))
						or "error"
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

function M.get_test_win_id()
	return test_win_id
end

function M.get_last_test_cmd()
	return last_test_cmd
end

return M

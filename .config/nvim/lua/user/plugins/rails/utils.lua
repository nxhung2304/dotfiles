local M = {}

function M.is_rails_project()
	return vim.fn.filereadable(vim.fn.getcwd() .. "/bin/rails") == 1
		or vim.fn.filereadable(vim.fn.getcwd() .. "/config/application.rb") == 1
end

function M.rails_guard(fn)
	if not M.is_rails_project() then
		vim.notify("Not a Rails project", vim.log.levels.WARN)
		return
	end
	fn()
end

local _named_terms = {}
function M.tmux_named_window(name, cmd)
	local Terminal = require("toggleterm.terminal").Terminal
	if not _named_terms[name] then
		_named_terms[name] = Terminal:new({
			cmd = cmd,
			display_name = name,
			direction = "vertical",
			hidden = true,
			close_on_exit = false,
		})
	end
	_named_terms[name]:toggle()
end

local _console_term = nil
local _console_initialized = false

function M.console_send_selection()
	local Terminal = require("toggleterm.terminal").Terminal
	local tmpfile = "/tmp/nvim_console_snippet.rb"

	-- <Cmd> mappings run while still in visual mode context, so '< / '> are not
	-- committed yet. Use getpos("v") (anchor) and getpos(".") (cursor) instead.
	local anchor = vim.fn.getpos("v")
	local cursor = vim.fn.getpos(".")
	local start_line = math.min(anchor[2], cursor[2])
	local end_line = math.max(anchor[2], cursor[2])
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	vim.fn.writefile(lines, tmpfile)

	if not _console_term then
		_console_initialized = false
		_console_term = Terminal:new({
			cmd = "bundle exec rails console",
			display_name = "rails console",
			direction = "float",
			hidden = true,
			close_on_exit = false,
			on_open = function(term)
				if not _console_initialized then
					-- Wait for irb/pry prompt before sending
					vim.defer_fn(function()
						_console_initialized = true
						term:send('load "' .. tmpfile .. '"')
					end, 5000)
				end
			end,
		})
		_console_term:toggle()
	else
		if not _console_term:is_open() then
			_console_term:open()
		end
		_console_term:send('load "' .. tmpfile .. '"')
	end
end

local cmd_win_id = nil
local cmd_buf_id = nil

function M.run_cmd(cmd, label, opts)
	label = label or cmd
	opts = opts or {}

	local origin_win = vim.api.nvim_get_current_win()

	local file_win = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if win ~= cmd_win_id then
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.api.nvim_get_option_value("buftype", { buf = buf }) ~= "terminal" then
				file_win = win
				break
			end
		end
	end
	file_win = file_win or origin_win

	if cmd_win_id and vim.api.nvim_win_is_valid(cmd_win_id) then
		vim.api.nvim_win_close(cmd_win_id, true)
	end
	if cmd_buf_id and vim.api.nvim_buf_is_valid(cmd_buf_id) then
		pcall(vim.api.nvim_buf_delete, cmd_buf_id, { force = true })
	end
	cmd_win_id = nil
	cmd_buf_id = nil

	vim.api.nvim_set_current_win(file_win)
	vim.cmd("botright vsplit")
	vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.38))
	cmd_win_id = vim.api.nvim_get_current_win()

	local term_buf = vim.api.nvim_create_buf(false, true)
	cmd_buf_id = term_buf
	vim.api.nvim_win_set_buf(cmd_win_id, term_buf)

	vim.wo[cmd_win_id].winbar = "%#TestRunning# ⠋ " .. label .. "%*"
	vim.wo[cmd_win_id].number = false
	vim.wo[cmd_win_id].signcolumn = "no"

	vim.keymap.set("n", "q", function()
		if cmd_win_id and vim.api.nvim_win_is_valid(cmd_win_id) then
			vim.api.nvim_win_close(cmd_win_id, true)
			cmd_win_id = nil
		end
	end, { buffer = term_buf, silent = true })

	local started_at = vim.uv.hrtime()

	vim.fn.termopen(cmd, {
		on_exit = function(_, code)
			vim.schedule(function()
				local elapsed = string.format("%.2fs", (vim.uv.hrtime() - started_at) / 1e9)
				if not (cmd_win_id and vim.api.nvim_win_is_valid(cmd_win_id)) then
					return
				end
				if code == 0 then
					vim.wo[cmd_win_id].winbar = string.format("%%#TestPassed# ✓ %s (%s)%%*", label, elapsed)
					vim.notify("✓ " .. label .. " (" .. elapsed .. ")", vim.log.levels.INFO)
				else
					vim.wo[cmd_win_id].winbar = string.format("%%#TestFailed# ✗ %s (%s)%%*", label, elapsed)
					vim.notify("✗ " .. label .. " failed (" .. elapsed .. ")", vim.log.levels.WARN)
				end
			end)
		end,
	})

	vim.bo[term_buf].filetype = "terminal"
	if opts.interactive then
		vim.cmd("startinsert")
	else
		vim.api.nvim_set_current_win(file_win)
	end
end

local function lazy_i18n_scope()
	local file = vim.fn.expand("%:p")
	-- app/views/users/index.html.erb -> users.index
	-- app/views/users/_form.html.erb -> users.form (strip leading _)
	local path = file:match("app/views/(.+)%.html%.[%a]+$")
		or file:match("app/views/(.+)%.%a+$")
	if not path then
		return nil
	end
	local parts = {}
	for seg in path:gmatch("[^/]+") do
		seg = seg:gsub("^_", "") -- strip partial prefix
		table.insert(parts, seg)
	end
	return table.concat(parts, ".")
end

local function extract_i18n_key()
	local line = vim.api.nvim_get_current_line()
	-- full key: t("users.index.title") or I18n.t(...) or translate(...)
	local key = line:match("I18n%.[Tt]%w*%s*%([^)]-['\"]([%w][%w%.%-_]*)['\"]")
		or line:match("translate%s*%([^)]-['\"]([%w][%w%.%-_]*)['\"]")
		or line:match("[^%a_]t%s*%([%s]*['\"]([%w][%w%.%-_]*)['\"]")
		or line:match("^%s*t%s*%([%s]*['\"]([%w][%w%.%-_]*)['\"]")
	if key then
		return key
	end
	-- lazy key: t(".title") -> resolve from file path
	local lazy = line:match("[^%a_]t%s*%([%s]*['\"](%.[%w%.%-_]+)['\"]")
		or line:match("^%s*t%s*%([%s]*['\"](%.[%w%.%-_]+)['\"]")
	if lazy then
		local scope = lazy_i18n_scope()
		if scope then
			return scope .. lazy -- e.g. "users.index.title"
		end
		return lazy:sub(2) -- strip leading dot as fallback
	end
end

function M.i18n_jump()
	local locales_dir = vim.fn.getcwd() .. "/config/locales"
	if vim.fn.isdirectory(locales_dir) == 0 then
		vim.notify("config/locales not found", vim.log.levels.WARN)
		return
	end
	local key = extract_i18n_key()
	if key then
		local last = key:match("[^%.]+$")
		-- "new: " (trailing space) matches only keys with an inline value, skipping bare parent keys
		Snacks.picker.grep({ cwd = locales_dir, search = last .. ": " })
	else
		Snacks.picker.grep({ cwd = locales_dir })
	end
end

function M.i18n_files()
	local dir = vim.fn.getcwd() .. "/config/locales"
	if vim.fn.isdirectory(dir) == 0 then
		vim.notify("config/locales not found", vim.log.levels.WARN)
		return
	end
	Snacks.picker.files({ dirs = { dir } })
end

function M.routes_grep()
	local Terminal = require("toggleterm.terminal").Terminal
	local tmpout = "/tmp/nvim_routes_sel.txt"
	local script = "/tmp/nvim_routes_fzf.sh"

	vim.fn.writefile({
		"#!/bin/sh",
		"rm -f /tmp/nvim_routes_sel.txt",
		"bundle exec rails routes | fzf --ansi --header-lines=1 --multi"
			.. " --bind 'ctrl-q:select-all+accept' > /tmp/nvim_routes_sel.txt",
	}, script)
	vim.fn.system("chmod +x " .. script)

	Terminal:new({
		cmd = script,
		direction = "float",
		hidden = true,
		close_on_exit = true,
		on_exit = function()
			vim.schedule(function()
				if vim.fn.filereadable(tmpout) == 0 then
					return
				end
				local lines = vim.fn.readfile(tmpout)
				local qflist = {}
				for _, line in ipairs(lines) do
					if vim.trim(line) ~= "" then
						table.insert(qflist, { text = vim.trim(line) })
					end
				end
				if #qflist > 0 then
					vim.fn.setqflist(qflist, "r")
					vim.cmd("copen")
				end
			end)
		end,
	}):toggle()
end

return M

local function is_rails_project()
	return vim.fn.filereadable(vim.fn.getcwd() .. "/bin/rails") == 1
		or vim.fn.filereadable(vim.fn.getcwd() .. "/config/application.rb") == 1
end

local function rails_guard(fn)
	if not is_rails_project() then
		vim.notify("Not a Rails project", vim.log.levels.WARN)
		return
	end
	fn()
end

local function tmux_named_window(name, cmd)
	local full =
		string.format("silent !tmux new-window -n '%s' '%s' 2>/dev/null || tmux select-window -t '%s'", name, cmd, name)
	vim.cmd(full)
end

local function tmux_float(cmd)
	vim.fn.system(string.format(
		"tmux display-popup -E -d '#{pane_current_path}' -w 80%% -h 80%% '%s'",
		cmd
	))
end

local function console_session_name()
	local hash = vim.fn.system("echo '" .. vim.fn.getcwd() .. "' | md5sum | cut -c1-8"):gsub("%s+", "")
	return "rails-console-" .. hash
end

local function console_send_selection()
	local session = console_session_name()
	local tmpfile = "/tmp/nvim_console_snippet.rb"
	-- <Cmd> mappings run while still in visual mode context, so '< / '> are not
	-- committed yet. Use getpos("v") (anchor) and getpos(".") (cursor) instead.
	local anchor = vim.fn.getpos("v")
	local cursor = vim.fn.getpos(".")
	local start_line = math.min(anchor[2], cursor[2])
	local end_line   = math.max(anchor[2], cursor[2])
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	vim.fn.writefile(lines, tmpfile)

	vim.fn.system("tmux has-session -t '" .. session .. "' 2>/dev/null")
	if vim.v.shell_error ~= 0 then
		vim.fn.system(
			"tmux new-session -d -s '" .. session .. "' -c '" .. vim.fn.getcwd() .. "' 'bundle exec rails console'"
		)
		-- wait for pry/irb prompt async, then send load
		vim.fn.jobstart(
			"until tmux capture-pane -t '" .. session .. "' -p | grep -qE 'pry|irb|>>'; do sleep 0.3; done;"
			.. " tmux send-keys -t '" .. session .. "' 'load \"" .. tmpfile .. "\"' Enter",
			{ detach = true }
		)
	else
		vim.fn.system("tmux send-keys -t '" .. session .. "' 'load \"" .. tmpfile .. "\"' Enter")
	end

	tmux_float("tmux attach-session -t " .. session)
end

local function routes_grep()
	local tmpout = "/tmp/nvim_routes_sel.txt"
	local script = "/tmp/nvim_routes_fzf.sh"
	local qflag  = ""

	-- Write to a script to avoid quoting hell inside tmux_float single-quote wrapping
	vim.fn.writefile({
		"#!/bin/sh",
		"rm -f /tmp/nvim_routes_sel.txt",
		"bundle exec rails routes | fzf --ansi --header-lines=1 --multi"
			.. qflag
			.. " --bind 'ctrl-q:select-all+accept' > /tmp/nvim_routes_sel.txt",
	}, script)
	vim.fn.system("chmod +x " .. script)

	tmux_float(script)  -- blocks until popup closes

	if vim.fn.filereadable(tmpout) == 0 then return end
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
end

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
	spinner_timer:start(0, 100, vim.schedule_wrap(function()
		if not vim.api.nvim_win_is_valid(win) then
			stop_spinner()
			return
		end
		vim.wo[win].winbar = string.format("%%#TestRunning# %s %s%%*", spinner_frames[idx], label)
		idx = (idx % #spinner_frames) + 1
	end))
end

local function set_winbar(win, status, label)
	if not vim.api.nvim_win_is_valid(win) then return end
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

	-- Count failures from summary line, fallback to qflist size if reporter crashed
	local f, e = content:match("(%d+) failures?, (%d+) errors?")
	fail_count = f and (tonumber(f) + tonumber(e)) or #qflist

	return qflist, fail_count
end

local function run_test(cmd)
	last_test_cmd = cmd

	local origin_win = vim.api.nvim_get_current_win()

	-- Find a non-terminal window to split from
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

	-- Close old window, delete old buffer
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
		local chunk = table.concat(
			vim.api.nvim_buf_get_lines(buf, cur - 1, math.min(cur + 4, total), false),
			"\n"
		)
		local file, lnum = chunk:match("%[([^%]]+):(%d+)%]:")
		if not file then return end
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
	vim.keymap.set("n", "gf",   jump_to_error_under_cursor, { buffer = term_buf, silent = true })


	local label = cmd:match("bundle exec rails test (.+)$") or "rails test"
	label = vim.fn.fnamemodify(label:gsub(":%d+$", ""), ":.")
	start_spinner(test_win_id, label)

	local started_at = vim.uv.hrtime()

	vim.fn.termopen(cmd, {
		on_exit = function(_, code)
			vim.schedule(function()
				stop_spinner()
				local buf = test_buf_id
				if not (buf and vim.api.nvim_buf_is_valid(buf)) then return end

				local elapsed = string.format("%.2fs", (vim.uv.hrtime() - started_at) / 1e9)
				local qflist, fail_count = parse_test_output(buf)

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
					end, 800)
				else
					local summary = fail_count > 0 and (fail_count .. " failure" .. (fail_count ~= 1 and "s" or "")) or "error"
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

local function toggle_test_panel()
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

return {
	{
		"yelog/i18n.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		ft = { "ruby", "eruby", "haml", "slim", "yaml" },
		config = function()
			require("i18n").setup({
				activation = "auto",
				locales = {},
				sources = { "config/locales/{locales}.yml" },
				auto_detect = {
					enabled = true,
					extensions = { "yml", "yaml", "json" },
					locale_dir_names = { "locales", "i18n", "locale" },
					max_depth = 6,
				},
				func_pattern = { "t", "I18n.t" },
				func_type = { "ruby", "eruby", "haml", "slim" },
				show_mode = "both",
				usage = { popup_type = "vim_ui" },
				i18n_keys = { popup_type = "vim_ui" },
				-- Resolve Rails lazy lookup: t(".title") in app/views/courses/edit.html.erb
				-- → "courses.edit.title"
				-- i18n.nvim strips the leading dot before calling the resolver,
				-- so detect lazy keys by inspecting the raw source line instead.
				namespace_resolver = function(bufnr, key, line)
					local raw = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
					if not raw:match([[t%s*%(%s*['"]%.]]) then return nil end
					local path = vim.api.nvim_buf_get_name(bufnr)
					local rel = path:match("app/views/(.+)%.[^.]+%.[^.]+$")
					if not rel then return nil end
					return rel:gsub("/", ".")
				end,
				namespace_separator = "",
			})
			local ok, cmp = pcall(require, "cmp")
			if ok then
				cmp.register_source("i18n", require("i18n.integration.cmp_source").new())
			end
		end,
		keys = {
			{ "<leader>ik", function() I18n.i18n_keys() end,           desc = "i18n Keys" },
			{ "<leader>in", function() I18n.next_locale() end,         desc = "i18n Next Locale" },
			{ "<leader>is", function() I18n.show_popup() end,          desc = "i18n Show Translations" },
			{ "<leader>io", function() I18n.toggle_origin() end,       desc = "i18n Toggle Origin" },
			{ "<leader>it", function() I18n.toggle_translation() end,  desc = "i18n Toggle Translation" },
			{ "<leader>ia", "<cmd>I18nAddKey<cr>",                     desc = "i18n Add Key" },
			{
				"gd",
				function()
					if require("i18n").i18n_definition() then return end
					vim.lsp.buf.definition()
				end,
				ft = { "ruby", "eruby", "haml", "slim" },
				desc = "i18n or LSP definition",
			},
		},
	},
	{
		"preservim/vimux",
		lazy = false,
		config = function()
			vim.g["VimuxOrientation"] = "h"
			vim.g["VimuxHeight"] = "33"
		end,
	},
	{
		"tpope/vim-rails",
		lazy = false,
		dependencies = { "preservim/vimux" },
		init = function()
			local function apply_hl()
				vim.api.nvim_set_hl(0, "TestRunning", { fg = "#fabd2f", bold = true })
				vim.api.nvim_set_hl(0, "TestPassed", { fg = "#b8bb26", bold = true })
				vim.api.nvim_set_hl(0, "TestFailed", { fg = "#fb4934", bold = true })
			end
			apply_hl()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
		end,
		keys = {
			-- Test
			{
				"<leader>tc",
				function()
					rails_guard(function()
						run_test("bundle exec rails test " .. vim.fn.expand("%:p") .. ":" .. vim.fn.line("."))
					end)
				end,
				desc = "Test at Cursor",
			},
			{
				"<leader>tf",
				function()
					rails_guard(function()
						run_test("bundle exec rails test " .. vim.fn.expand("%:p"))
					end)
				end,
				desc = "Test File",
			},
			{
				"<leader>ta",
				function() rails_guard(function() run_test("bundle exec rails test") end) end,
				desc = "Test All",
			},
			{
				"<leader>tl",
				function()
					rails_guard(function()
						if last_test_cmd then
							run_test(last_test_cmd)
						else
							vim.notify("No previous test command", vim.log.levels.WARN)
						end
					end)
				end,
				desc = "Rerun Last Test",
			},
			{ "<leader>tt", toggle_test_panel, desc = "Toggle Test Panel" },
			{
				"]f",
				function()
					if not (test_win_id and vim.api.nvim_win_is_valid(test_win_id)) then
						vim.notify("No test output open", vim.log.levels.WARN)
						return
					end
					local buf = vim.api.nvim_win_get_buf(test_win_id)
					local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
					local cur = vim.api.nvim_win_get_cursor(test_win_id)[1]
					for i = cur + 1, #lines do
						if lines[i]:match("^Failure:") or lines[i]:match("^Error:") then
							vim.api.nvim_set_current_win(test_win_id)
							vim.api.nvim_win_set_cursor(test_win_id, { i, 0 })
							return
						end
					end
					vim.notify("No more failures", vim.log.levels.INFO)
				end,
				desc = "Next test failure",
			},
			{
				"[f",
				function()
					if not (test_win_id and vim.api.nvim_win_is_valid(test_win_id)) then
						vim.notify("No test output open", vim.log.levels.WARN)
						return
					end
					local buf = vim.api.nvim_win_get_buf(test_win_id)
					local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
					local cur = vim.api.nvim_win_get_cursor(test_win_id)[1]
					for i = cur - 1, 1, -1 do
						if lines[i]:match("^Failure:") or lines[i]:match("^Error:") then
							vim.api.nvim_set_current_win(test_win_id)
							vim.api.nvim_win_set_cursor(test_win_id, { i, 0 })
							return
						end
					end
					vim.notify("No more failures", vim.log.levels.INFO)
				end,
				desc = "Prev test failure",
			},
			{
				"<leader>to",
				function()
					if test_win_id and vim.api.nvim_win_is_valid(test_win_id) then
						vim.api.nvim_set_current_win(test_win_id)
					else
						vim.notify("No test output open", vim.log.levels.WARN)
					end
				end,
				desc = "Focus Test Output",
			},
			-- Navigation
			{ "<leader>rc", "<cmd>Econtroller<cr>", desc = "Controller" },
			{ "<leader>rm", "<cmd>Emodel<cr>",       desc = "Model" },
			{ "<leader>rv", "<cmd>Eview<cr>",         desc = "View" },
			{ "<leader>ru", "<cmd>Eunittest<cr>",     desc = "Unittest" },
			{ "<leader>rf", "<cmd>Efixture<cr>",      desc = "Fixture" },
			{ "<leader>ri", "<cmd>Emigration<cr>",    desc = "Migration" },
			{ "<leader>rr", "<cmd>Einitializer<cr>",  desc = "Routes" },
			-- Runtime (tmux persistent windows)
			{
				"<leader>Rc",
				function() rails_guard(function() tmux_named_window("console", "bundle exec rails console") end) end,
				desc = "Rails Console",
			},
			{
				"<leader>Rs",
				function() rails_guard(function() tmux_named_window("server", "bundle exec rails server") end) end,
				desc = "Rails Server",
			},
			{
				"<leader>Rl",
				function() rails_guard(function() tmux_named_window("logs", "tail -f log/development.log") end) end,
				desc = "Rails Logs",
			},
			{
				"<leader>Rm",
				function() rails_guard(function() vim.cmd("VimuxRunCommand('bundle exec rails db:migrate')") end) end,
				desc = "DB Migrate",
			},
			{
				"<leader>RS",
				function() rails_guard(function() vim.cmd("VimuxRunCommand('bundle exec rails db:seed')") end) end,
				desc = "DB Seed",
			},
			{
				"<leader>RR",
				function() rails_guard(function() vim.cmd("VimuxRunCommand('bundle exec rails db:migrate:reset')") end) end,
				desc = "DB Migrate reset",
			},
			{
				"<leader>Rg",
				function() rails_guard(function() vim.cmd("VimuxPromptCommand('bundle exec rails generate ')") end) end,
				desc = "Rails Generate",
			},
			{
				"<leader>Re",
				function() rails_guard(console_send_selection) end,
				mode = "v",
				desc = "Send selection to console",
			},
			{
				"<leader>Rr",
				function() rails_guard(routes_grep) end,
				desc = "Routes grep",
			},
			-- Rubocop
			{
				"<leader>Rb",
				function()
					vim.cmd("VimuxRunCommand('bundle exec rubocop " .. vim.fn.expand("%:p") .. "')")
				end,
				desc = "Rubocop Check File",
			},
			{ "<leader>RB", "<cmd>VimuxRunCommand('bundle exec rubocop')<cr>",    desc = "Rubocop Check All" },
			{
				"<leader>Rf",
				function()
					vim.cmd("VimuxRunCommand('bundle exec rubocop -A " .. vim.fn.expand("%:p") .. "')")
				end,
				desc = "Rubocop Fix File",
			},
			{ "<leader>RF", "<cmd>VimuxRunCommand('bundle exec rubocop -A')<cr>", desc = "Rubocop Fix All" },
		},
	},
}

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

function M.tmux_named_window(name, cmd)
	local full =
		string.format("silent !tmux new-window -n '%s' '%s' 2>/dev/null || tmux select-window -t '%s'", name, cmd, name)
	vim.cmd(full)
end

function M.tmux_float(cmd)
	vim.fn.system(string.format("tmux display-popup -E -d '#{pane_current_path}' -w 80%% -h 80%% '%s'", cmd))
end

local function console_session_name()
	local hash = vim.fn.system("echo '" .. vim.fn.getcwd() .. "' | md5sum | cut -c1-8"):gsub("%s+", "")
	return "rails-console-" .. hash
end

function M.console_send_selection()
	local session = console_session_name()
	local tmpfile = "/tmp/nvim_console_snippet.rb"
	-- <Cmd> mappings run while still in visual mode context, so '< / '> are not
	-- committed yet. Use getpos("v") (anchor) and getpos(".") (cursor) instead.
	local anchor = vim.fn.getpos("v")
	local cursor = vim.fn.getpos(".")
	local start_line = math.min(anchor[2], cursor[2])
	local end_line = math.max(anchor[2], cursor[2])
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	vim.fn.writefile(lines, tmpfile)

	vim.fn.system("tmux has-session -t '" .. session .. "' 2>/dev/null")
	if vim.v.shell_error ~= 0 then
		vim.fn.system(
			"tmux new-session -d -s '" .. session .. "' -c '" .. vim.fn.getcwd() .. "' 'bundle exec rails console'"
		)
		vim.fn.jobstart(
			"until tmux capture-pane -t '"
				.. session
				.. "' -p | grep -qE 'pry|irb|>>'; do sleep 0.3; done;"
				.. " tmux send-keys -t '"
				.. session
				.. "' 'load \""
				.. tmpfile
				.. "\"' Enter",
			{ detach = true }
		)
	else
		vim.fn.system("tmux send-keys -t '" .. session .. "' 'load \"" .. tmpfile .. "\"' Enter")
	end

	M.tmux_float("tmux attach-session -t " .. session)
end

function M.routes_grep()
	local tmpout = "/tmp/nvim_routes_sel.txt"
	local script = "/tmp/nvim_routes_fzf.sh"

	vim.fn.writefile({
		"#!/bin/sh",
		"rm -f /tmp/nvim_routes_sel.txt",
		"bundle exec rails routes | fzf --ansi --header-lines=1 --multi"
			.. " --bind 'ctrl-q:select-all+accept' > /tmp/nvim_routes_sel.txt",
	}, script)
	vim.fn.system("chmod +x " .. script)

	M.tmux_float(script)

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
end

return M

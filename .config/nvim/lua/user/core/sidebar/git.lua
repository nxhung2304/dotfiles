local M = {}
local base = require("user.core.sidebar.base")

local state = {
	sidebar_buf = nil,
	sidebar_win = nil,
	source_win  = nil,
	entries     = {},
	augroup     = vim.api.nvim_create_augroup("GitSidebar", { clear = true }),
}

local function setup_hl()
	vim.api.nvim_set_hl(0, "GitSidebarModified", { link = "DiagnosticWarn",  default = true })
	vim.api.nvim_set_hl(0, "GitSidebarAdded",    { link = "DiagnosticHint",  default = true })
	vim.api.nvim_set_hl(0, "GitSidebarDeleted",  { link = "DiagnosticError", default = true })
	vim.api.nvim_set_hl(0, "GitSidebarStaged",   { link = "DiagnosticHint",  default = true })
	vim.api.nvim_set_hl(0, "GitSidebarKey",      { link = "Function",        default = true })
	vim.api.nvim_set_hl(0, "GitSidebarHintDesc", { link = "Comment",         default = true })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })
setup_hl()


local status_icons = {
	M = "󰏫 ", A = "󰱒 ", D = "󰍷 ", R = "󰁕 ", C = "󰁕 ", ["?"] = "󰝒 ",
}

local function file_icon(path)
	local ok, devicons = pcall(require, "nvim-web-devicons")
	if not ok then return "  " end
	local fname = vim.fn.fnamemodify(path, ":t")
	local ext   = vim.fn.fnamemodify(path, ":e")
	local icon, hl = devicons.get_icon(fname, ext, { default = true })
	return icon or " ", hl or "Normal"
end

local _count_cache = nil

local function parse_status()
	local raw = vim.fn.systemlist(
		"git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " status --porcelain 2>/dev/null"
	)
	local staged, unstaged = {}, {}
	for _, line in ipairs(raw) do
		if #line >= 4 then
			local x    = line:sub(1, 1)
			local y    = line:sub(2, 2)
			local path = line:sub(4)
			if x ~= " " and x ~= "?" then
				table.insert(staged,   { status = x,                      path = path })
			end
			if y ~= " " then
				table.insert(unstaged, { status = y == "?" and "?" or y,  path = path })
			end
		end
	end
	return staged, unstaged
end

local function get_branch_info()
	local cwd    = vim.fn.shellescape(vim.fn.getcwd())
	local branch = vim.fn.system("git -C " .. cwd .. " rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("%s+$", "")
	if branch == "" or branch:match("^fatal") then return nil end

	local ab     = vim.fn.system("git -C " .. cwd .. " rev-list --left-right --count HEAD...@{upstream} 2>/dev/null"):gsub("%s+$", "")
	local ahead, behind = ab:match("(%d+)%s+(%d+)")

	local info = " " .. branch
	if ahead and behind then
		local a, b = tonumber(ahead), tonumber(behind)
		if a and a > 0 then info = info .. " ↑" .. a end
		if b and b > 0 then info = info .. " ↓" .. b end
	end
	return info
end

function M.get_count()
	if _count_cache ~= nil then return _count_cache > 0 and _count_cache or nil end
	local r = vim.fn.system(
		"git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " status --porcelain 2>/dev/null | wc -l"
	)
	_count_cache = tonumber(r:match("%d+")) or 0
	return _count_cache > 0 and _count_cache or nil
end

local ns = vim.api.nvim_create_namespace("GitSidebarHl")

-- Keep at most 3 path components (parent2/parent1/filename).
-- Deeper paths are shown as "…/parent/filename".
local function format_path(path)
	local parts = vim.split(path, "/", { plain = true })
	if #parts <= 4 then return path end
	return "…/" .. parts[#parts - 2] .. "/" .. parts[#parts - 1] .. "/" .. parts[#parts]
end

local function render()
	if not base.is_valid(state) then return end
	local staged, unstaged = parse_status()

	local seen = {}
	for _, f in ipairs(staged)   do seen[f.path] = true end
	for _, f in ipairs(unstaged) do seen[f.path] = true end
	local total = 0
	for _ in pairs(seen) do total = total + 1 end
	_count_cache = total

	local lines   = {}
	local entries = {}

	local function add_section(title, files, is_staged)
		table.insert(lines,   title .. " (" .. #files .. ")")
		table.insert(entries, { type = "header" })

		if #files == 0 then
			table.insert(lines,   "  no files")
			table.insert(entries, { type = "empty" })
		else
			for _, f in ipairs(files) do
				local icon, icon_hl = file_icon(f.path)
				local display        = format_path(f.path)
				table.insert(lines,   "  " .. icon .. " " .. display)
				table.insert(entries, { type = "file", path = f.path, status = f.status, staged = is_staged, icon_hl = icon_hl })
			end
		end
	end

	add_section("▾ Staged", staged, true)
	table.insert(lines, ""); table.insert(entries, { type = "empty" })
	add_section("▾ Changes", unstaged, false)

	if total == 0 then
		lines   = { "  clean" }
		entries = { { type = "empty" } }
	end

	state.entries = entries
	base.set_lines(state, lines)

	vim.api.nvim_buf_clear_namespace(state.sidebar_buf, ns, 0, -1)
	for i, entry in ipairs(entries) do
		if entry.type == "header" then
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "Title", i - 1, 0, -1)
		elseif entry.type == "file" then
			local text_hl = entry.staged and "GitSidebarStaged" or "Normal"
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, entry.icon_hl or "Normal", i - 1, 2, 5)
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, text_hl, i - 1, 5, -1)
		end
	end

	require("user.core.sidebar").set_tabbar(state.sidebar_win, get_branch_info())
end

-- Opens a floating scratch buffer for composing a commit message.
-- <CR> (normal) or <C-s> (insert) to commit; q to cancel.
local function open_commit_buf(amend)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype  = "nofile"
	vim.bo[buf].filetype = "gitcommit"

	if amend then
		local lines = vim.fn.systemlist(
			"git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " log -1 --pretty=%B 2>/dev/null"
		)
		while #lines > 0 and lines[#lines] == "" do table.remove(lines) end
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end

	local width  = math.min(80, math.floor(vim.o.columns * 0.65))
	local height = 12
	local row    = math.floor((vim.o.lines - height) / 2)
	local col    = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative  = "editor",
		width     = width,
		height    = height,
		row       = row,
		col       = col,
		style     = "minimal",
		border    = "rounded",
		title     = amend and " Amend commit " or " Commit message ",
		title_pos = "center",
	})

	vim.cmd("startinsert")

	local function do_commit()
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
		if #lines == 0 then
			vim.notify("Commit message cannot be empty", vim.log.levels.WARN)
			return
		end

		if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end

		local tmpfile = vim.fn.tempname()
		local f = io.open(tmpfile, "w")
		if f then f:write(table.concat(lines, "\n") .. "\n"); f:close() end

		local cwd = vim.fn.shellescape(vim.fn.getcwd())
		local flag = amend and " commit --amend -F " or " commit -F "
		local result = vim.fn.system("git -C " .. cwd .. flag .. vim.fn.shellescape(tmpfile))
		vim.fn.delete(tmpfile)

		local ok = vim.v.shell_error == 0
		vim.notify(
			ok and (amend and "Amended!" or "Committed!")
			   or ("Commit failed:\n" .. result),
			ok and vim.log.levels.INFO or vim.log.levels.ERROR
		)
		_count_cache = nil
		vim.schedule(render)
	end

	local kopts = { buffer = buf, nowait = true }
	vim.keymap.set("n", "<CR>", do_commit, kopts)
	vim.keymap.set("i", "<C-s>", function() vim.cmd("stopinsert"); do_commit() end, kopts)
	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
	end, kopts)
end

local function git_async(args, label)
	local cwd  = vim.fn.getcwd()
	local errs = {}
	vim.notify(label .. "...", vim.log.levels.INFO)
	vim.fn.jobstart(
		{ "git", "-C", cwd, unpack(args) },
		{
			stderr_buffered = true,
			on_stderr = function(_, data)
				for _, l in ipairs(data or {}) do
					if l ~= "" then table.insert(errs, l) end
				end
			end,
			on_exit = function(_, code)
				vim.schedule(function()
					if code == 0 then
						vim.notify(label .. " successful!", vim.log.levels.INFO)
					else
						local detail = #errs > 0 and (":\n" .. table.concat(errs, "\n")) or ""
						vim.notify(label .. " failed" .. detail, vim.log.levels.ERROR)
					end
					_count_cache = nil
					if base.is_valid(state) then render() end
				end)
			end,
		}
	)
end

local function open_help()
	local map = {
		{ "Stage / Unstage", "" },
		{ "<CR>", "open file in editor" },
		{ "d",    "open CodeDiff" },
		{ "s",    "stage file" },
		{ "u",    "unstage file" },
		{ "S",    "stage all  (git add -A)" },
		{ "U",    "unstage all" },
		{ "", "" },
		{ "Commit", "" },
		{ "c",    "commit  (opens message buffer)" },
		{ "C",    "amend last commit" },
		{ "", "" },
		{ "Remote", "" },
		{ "P",    "push" },
		{ "p",    "pull" },
		{ "F",    "fetch" },
		{ "", "" },
		{ "Misc", "" },
		{ "r",    "refresh" },
		{ "q",    "close sidebar" },
		{ ">/<",  "resize" },
		{ "?",    "toggle this help" },
	}

	local width = 42
	local lines, hl_keys = {}, {}
	for _, row in ipairs(map) do
		local key, desc = row[1], row[2]
		if desc == "" then
			-- section header or blank
			table.insert(lines, key == "" and "" or ("  " .. key))
			table.insert(hl_keys, key ~= "" and #lines or nil)
		else
			local pad = string.rep(" ", 6 - vim.fn.strdisplaywidth(key))
			table.insert(lines, "  " .. key .. pad .. desc)
			table.insert(hl_keys, { line = #lines - 1, key_end = 2 + #key })
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	local height = #lines
	local row    = math.floor((vim.o.lines   - height) / 2)
	local col    = math.floor((vim.o.columns - width)  / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative  = "editor",
		width     = width,
		height    = height,
		row       = row,
		col       = col,
		style     = "minimal",
		border    = "rounded",
		title     = " Git Sidebar — Keys ",
		title_pos = "center",
	})

	local ns_h = vim.api.nvim_create_namespace("GitSidebarHelpHl")
	for _, info in ipairs(hl_keys) do
		if type(info) == "table" then
			vim.api.nvim_buf_add_highlight(buf, ns_h, "GitSidebarKey", info.line, 2, info.key_end)
		elseif type(info) == "number" then
			vim.api.nvim_buf_add_highlight(buf, ns_h, "Title", info - 1, 0, -1)
		end
	end

	local close = function() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end end
	for _, key in ipairs({ "q", "?", "<Esc>" }) do
		vim.keymap.set("n", key, close, { buffer = buf, nowait = true })
	end
end

local function setup_keymaps()
	local opts = { buffer = state.sidebar_buf, nowait = true }

	vim.keymap.set("n", "<CR>", function()
		local line  = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
		local entry = state.entries[line]
		if not entry or entry.type ~= "file" then return end
		local win = base.find_target_win(state)
		if win then
			vim.api.nvim_set_current_win(win)
			vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
		end
	end, opts)

	vim.keymap.set("n", "d", function()
		local line  = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
		local entry = state.entries[line]
		if not entry or entry.type ~= "file" then return end
		local win = base.find_target_win(state)
		if not win then return end

		local before = {}
		for _, w in ipairs(vim.api.nvim_list_wins()) do before[w] = true end

		vim.api.nvim_set_current_win(win)
		vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
		vim.cmd("CodeDiff")

		-- nui.nvim creates windows asynchronously, so wait 80 ms before
		-- snapshotting CodeDiff's windows. Then poll every 100 ms; once all
		-- CodeDiff windows are gone, give it another 50 ms to finish its own
		-- focus-restoration, then take over and focus the sidebar.
		local sidebar = state.sidebar_win
		vim.defer_fn(function()
			local diff_wins = {}
			for _, w in ipairs(vim.api.nvim_list_wins()) do
				if not before[w] then diff_wins[w] = true end
			end
			if not next(diff_wins) then return end

			local function poll(n)
				if n <= 0 then return end
				if not vim.api.nvim_win_is_valid(sidebar) then return end
				local alive = false
				for w in pairs(diff_wins) do
					if vim.api.nvim_win_is_valid(w) then alive = true; break end
				end
				if alive then
					vim.defer_fn(function() poll(n - 1) end, 100)
				else
					vim.defer_fn(function()
						if vim.api.nvim_win_is_valid(sidebar) then
							vim.api.nvim_set_current_win(sidebar)
						end
					end, 50)
				end
			end
			poll(300)   -- up to 30 s
		end, 80)
	end, opts)

	-- Stage / Unstage single file
	vim.keymap.set("n", "s", function()
		local line  = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
		local entry = state.entries[line]
		if not entry or entry.type ~= "file" or entry.staged ~= false then return end
		vim.fn.system("git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " add " .. vim.fn.shellescape(entry.path))
		_count_cache = nil
		render()
	end, opts)

	vim.keymap.set("n", "u", function()
		local line  = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
		local entry = state.entries[line]
		if not entry or entry.type ~= "file" or entry.staged ~= true then return end
		vim.fn.system("git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " restore --staged " .. vim.fn.shellescape(entry.path))
		_count_cache = nil
		render()
	end, opts)

	-- Stage / Unstage all
	vim.keymap.set("n", "S", function()
		vim.fn.system("git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " add -A")
		_count_cache = nil
		render()
	end, opts)

	vim.keymap.set("n", "U", function()
		vim.fn.system("git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " restore --staged .")
		_count_cache = nil
		render()
	end, opts)

	-- Commit
	vim.keymap.set("n", "c", function() open_commit_buf(false) end, opts)
	vim.keymap.set("n", "C", function() open_commit_buf(true)  end, opts)

	-- Remote
	vim.keymap.set("n", "P", function() git_async({ "push"  }, "Push")  end, opts)
	vim.keymap.set("n", "p", function() git_async({ "pull"  }, "Pull")  end, opts)
	vim.keymap.set("n", "F", function() git_async({ "fetch" }, "Fetch") end, opts)

	vim.keymap.set("n", "r", function() render() end, opts)
	vim.keymap.set("n", "?", open_help, opts)
	base.add_common_keymaps(state, M.close)
end

function M.open()
	local k, h = "%#GitSidebarKey#", "%#GitSidebarHintDesc#"
	base.open_win(state, {
		filetype   = "GitSidebar",
		statusline = " "
			.. k.."s"..h..":stage  "..k.."u"..h..":unstage  "
			.. k.."c"..h..":commit  "..k.."d"..h..":diff  "
			.. k.."?"..h..":help",
		cursorline = true,
	})

	setup_keymaps()
	render()
	vim.api.nvim_set_current_win(state.sidebar_win)

	vim.api.nvim_create_autocmd({ "BufWritePost", "ShellCmdPost" }, {
		group    = state.augroup,
		callback = function() if base.is_valid(state) then render() end end,
	})
	base.on_win_closed(state, function() state.entries = {} end)
end

function M.close()
	base.close(state)
	state.entries = {}
end

vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
	group    = vim.api.nvim_create_augroup("GitSidebarCount", { clear = true }),
	callback = function() _count_cache = nil end,
})

vim.schedule(function()
	require("user.core.sidebar").register({
		id        = "git",
		label     = "Git",
		icon      = "",
		open      = M.open,
		close     = M.close,
		is_open   = function() return base.is_valid(state) end,
		get_win   = function() return state.sidebar_win end,
		get_count = M.get_count,
	})
end)

return M

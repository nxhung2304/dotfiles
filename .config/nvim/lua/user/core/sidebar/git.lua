local M = {}
local base = require("user.core.sidebar.base")

local state = {
	sidebar_buf = nil,
	sidebar_win = nil,
	source_win  = nil,
	entries     = {},
	augroup     = vim.api.nvim_create_augroup("GitSidebar", { clear = true }),
}

local diff_state = {
	active    = false,
	left_win  = nil,
	right_win = nil,
	entry_idx = nil,
}

local function setup_hl()
	vim.api.nvim_set_hl(0, "GitSidebarModified", { link = "DiagnosticWarn",  default = true })
	vim.api.nvim_set_hl(0, "GitSidebarAdded",    { link = "DiagnosticHint",  default = true })
	vim.api.nvim_set_hl(0, "GitSidebarDeleted",  { link = "DiagnosticError", default = true })
	vim.api.nvim_set_hl(0, "GitSidebarStaged",   { link = "DiagnosticHint",  default = true })
	vim.api.nvim_set_hl(0, "GitSidebarKey",           { link = "Function",   default = true })
	vim.api.nvim_set_hl(0, "GitSidebarHintDesc",      { link = "Comment",    default = true })
	vim.api.nvim_set_hl(0, "GitSidebarBranchCurrent", { link = "Statement",  default = true })
	vim.api.nvim_set_hl(0, "GitSidebarStashRef",      { link = "Comment",    default = true })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })
setup_hl()


local function file_icon(path)
	local ok, devicons = pcall(require, "nvim-web-devicons")
	if not ok then return "  " end
	local fname = vim.fn.fnamemodify(path, ":t")
	local ext   = vim.fn.fnamemodify(path, ":e")
	local icon, hl = devicons.get_icon(fname, ext, { default = true })
	return icon or " ", hl or "Normal"
end

local _count_cache = nil

-- ── Git helpers ──

local function git_run(args)
	return vim.fn.system(vim.list_extend({ "git", "-C", vim.fn.getcwd() }, args))
end

local function git_run_lines(args)
	return vim.fn.systemlist(vim.list_extend({ "git", "-C", vim.fn.getcwd() }, args))
end

-- ── Floating window helper ──

local function center_float(buf, width, height, title)
	local row = math.floor((vim.o.lines   - height) / 2)
	local col = math.floor((vim.o.columns - width)  / 2)
	return vim.api.nvim_open_win(buf, true, {
		relative = "editor", width = width, height = height,
		row = row, col = col, style = "minimal", border = "rounded",
		title = title, title_pos = "center",
	})
end

-- ── Status parsing ──

local function parse_status()
	local raw = git_run_lines({ "status", "--porcelain" })
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


local BRANCH_LIMIT = 8

local function parse_branches()
	local current  = vim.trim(git_run({ "branch", "--show-current" }))
	local all      = git_run_lines({ "branch", "--sort=-committerdate", "--format=%(refname:short)" })
	local branches = {}
	for _, b in ipairs(all) do
		if b ~= "" then
			table.insert(branches, { name = b, is_current = (b == current) })
			if #branches >= BRANCH_LIMIT then break end
		end
	end
	return branches
end

local function parse_stashes()
	local raw     = git_run_lines({ "stash", "list" })
	local stashes = {}
	for _, line in ipairs(raw) do
		local ref, msg = line:match("^(stash@{%d+}):%s*(.+)$")
		if ref then
			table.insert(stashes, { ref = ref, message = msg })
		end
	end
	return stashes
end

function M.get_count()
	if _count_cache ~= nil then return _count_cache > 0 and _count_cache or nil end
	local lines = git_run_lines({ "status", "--porcelain" })
	_count_cache = #lines
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

-- ── Render ──

local render  -- forward declaration

local fold_state = { staged = false, changes = false, commits = false, branches = false, stashes = false }

local function refresh()
	_count_cache = nil
	render()
end

render = function()
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

	local function add_section(title, key, files, is_staged)
		local icon = fold_state[key] and "▸" or "▾"
		table.insert(lines,   icon .. " " .. title .. " (" .. #files .. ")")
		table.insert(entries, { type = "header", section = key })
		if fold_state[key] then return end
		if #files == 0 then
			table.insert(lines,   "  no files")
			table.insert(entries, { type = "empty" })
		else
			for _, f in ipairs(files) do
				local ficon, icon_hl = file_icon(f.path)
				local display         = format_path(f.path)
				table.insert(lines,   "  " .. ficon .. " " .. display)
				table.insert(entries, { type = "file", path = f.path, status = f.status, staged = is_staged, icon_hl = icon_hl })
			end
		end
	end

	add_section("Staged", "staged", staged, true)
	table.insert(lines, ""); table.insert(entries, { type = "empty" })
	add_section("Changes", "changes", unstaged, false)

	if total == 0 then
		lines   = { "  clean" }
		entries = { { type = "empty" } }
	end

	-- ── Recent commits (always at bottom) ──
	local commits = git_run_lines({ "log", "-5", "--format=%h %s" })
	if #commits > 0 then
		table.insert(lines, ""); table.insert(entries, { type = "empty" })
		local cicon = fold_state.commits and "▸" or "▾"
		table.insert(lines,   cicon .. " Recent commits")
		table.insert(entries, { type = "header", section = "commits" })
		if not fold_state.commits then
			for _, raw in ipairs(commits) do
				local hash, msg = raw:match("^(%S+)%s+(.+)$")
				if hash then
					table.insert(lines,   "  " .. hash .. " " .. msg)
					table.insert(entries, { type = "commit", hash = hash })
				end
			end
		end
	end

	-- ── Branches ──
	local branches = parse_branches()
	if #branches > 0 then
		table.insert(lines, ""); table.insert(entries, { type = "empty" })
		local bicon  = fold_state.branches and "▸" or "▾"
		local blabel = #branches >= BRANCH_LIMIT and ("Recent branches (top " .. BRANCH_LIMIT .. ")") or ("Branches (" .. #branches .. ")")
		table.insert(lines,   bicon .. " " .. blabel)
		table.insert(entries, { type = "header", section = "branches" })
		if not fold_state.branches then
			for _, b in ipairs(branches) do
				local marker = b.is_current and "* " or "  "
				table.insert(lines,   "  " .. marker .. b.name)
				table.insert(entries, { type = "branch", name = b.name, is_current = b.is_current })
			end
		end
	end

	-- ── Stashes ──
	local stashes = parse_stashes()
	if #stashes > 0 then
		table.insert(lines, ""); table.insert(entries, { type = "empty" })
		local sicon = fold_state.stashes and "▸" or "▾"
		table.insert(lines,   sicon .. " Stashes (" .. #stashes .. ")")
		table.insert(entries, { type = "header", section = "stashes" })
		if not fold_state.stashes then
			for _, st in ipairs(stashes) do
				local msg = st.message
				if vim.fn.strdisplaywidth(msg) > 38 then
					msg = msg:sub(1, 37) .. "…"
				end
				table.insert(lines,   "  " .. st.ref .. " " .. msg)
				table.insert(entries, { type = "stash", ref = st.ref, message = st.message, ref_len = #st.ref })
			end
		end
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
		elseif entry.type == "commit" then
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "Comment", i - 1, 2, 9)
		elseif entry.type == "branch" then
			if entry.is_current then
				vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "GitSidebarBranchCurrent", i - 1, 0, -1)
			end
		elseif entry.type == "stash" then
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "GitSidebarStashRef", i - 1, 2, 2 + entry.ref_len)
		end
	end

	require("user.core.sidebar").set_tabbar(state.sidebar_win)
end

-- ── Cursor helper ──

local function cursor_entry()
	if not base.is_valid(state) then return nil, nil end
	local line = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
	return state.entries[line], line
end

-- ── Commit buffer ──

-- Opens a floating scratch buffer for composing a commit message.
-- <CR> (normal) or <C-s> (insert) to commit; q to cancel.
local function open_commit_buf(amend)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype  = "nofile"
	vim.bo[buf].filetype = "gitcommit"

	if amend then
		local lines = git_run_lines({ "log", "-1", "--pretty=%B" })
		while #lines > 0 and lines[#lines] == "" do table.remove(lines) end
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end

	local width  = math.min(80, math.floor(vim.o.columns * 0.65))
	local height = 12
	local win    = center_float(buf, width, height, amend and " Amend commit " or " Commit message ")

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

		local flag   = amend and { "commit", "--amend", "-F" } or { "commit", "-F" }
		local result = git_run(vim.list_extend(flag, { tmpfile }))
		vim.fn.delete(tmpfile)

		local ok = vim.v.shell_error == 0
		vim.notify(
			ok and (amend and "Amended!" or "Committed!")
			   or ("Commit failed:\n" .. result),
			ok and vim.log.levels.INFO or vim.log.levels.ERROR
		)
		vim.schedule(refresh)
	end

	local kopts = { buffer = buf, nowait = true }
	vim.keymap.set("n", "<CR>", do_commit, kopts)
	vim.keymap.set("i", "<C-s>", function() vim.cmd("stopinsert"); do_commit() end, kopts)
	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
	end, kopts)
end

-- ── Async git ops ──

local function git_async(args, label)
	local cwd  = vim.fn.getcwd()
	local errs = {}
	vim.notify(label .. "...", vim.log.levels.INFO)
	vim.fn.jobstart(
		{ "git", "-C", cwd, table.unpack(args) },
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
					if base.is_valid(state) then refresh() end
				end)
			end,
		}
	)
end

-- ── Help float ──

local function open_help()
	-- {} = blank line, { "Section" } = header, { "key", "desc" } = key entry
	local map = {
		{ "Sidebar" },
		{ "<CR>", "open two-panel diff" },
		{ "s",    "stage file" },
		{ "u",    "unstage file" },
		{ "S",    "stage all  (git add -A)" },
		{ "U",    "unstage all" },
		{ "x",    "discard file changes" },
		{ "X",    "discard all changes" },
		{ "z",    "fold / unfold section" },
		{},
		{ "Diff view" },
		{ "q",    "close diff" },
		{ "]f",   "next file diff" },
		{ "[f",   "prev file diff" },
		{ "-",    "stage / unstage file" },
		{ "]c",   "next hunk  (built-in)" },
		{ "[c",   "prev hunk  (built-in)" },
		{},
		{ "Commit" },
		{ "c",    "commit  (opens message buffer)" },
		{ "C",    "amend last commit" },
		{},
		{ "Remote" },
		{ "P",    "push" },
		{ "p",    "pull" },
		{ "F",    "fetch" },
		{},
		{ "Branch" },
		{ "<CR>", "checkout branch" },
		{},
		{ "Stash" },
		{ "<CR>", "pop stash  (apply + drop)" },
		{ "a",    "apply stash  (keep in list)" },
		{ "d",    "drop stash" },
		{},
		{ "Misc" },
		{ "r",    "refresh" },
		{ "q",    "close sidebar" },
		{ ">/<",  "resize" },
		{ "?",    "toggle this help" },
	}

	local width = 42
	local lines, hl_ranges = {}, {}
	for _, row in ipairs(map) do
		if #row == 0 then
			table.insert(lines, "")
		elseif #row == 1 then
			table.insert(lines, "  " .. row[1])
			table.insert(hl_ranges, { type = "header", line = #lines - 1 })
		else
			local key, desc = row[1], row[2]
			local pad = string.rep(" ", 6 - vim.fn.strdisplaywidth(key))
			table.insert(lines, "  " .. key .. pad .. desc)
			table.insert(hl_ranges, { type = "key", line = #lines - 1, key_end = 2 + #key })
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	local win    = center_float(buf, width, #lines, " Git Sidebar — Keys ")
	local ns_h   = vim.api.nvim_create_namespace("GitSidebarHelpHl")
	for _, info in ipairs(hl_ranges) do
		if info.type == "key" then
			vim.api.nvim_buf_add_highlight(buf, ns_h, "GitSidebarKey", info.line, 2, info.key_end)
		elseif info.type == "header" then
			vim.api.nvim_buf_add_highlight(buf, ns_h, "Title", info.line, 0, -1)
		end
	end

	local close = function() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end end
	for _, key in ipairs({ "q", "?", "<Esc>" }) do
		vim.keymap.set("n", key, close, { buffer = buf, nowait = true })
	end
end

-- ── Diff helpers ──

local function diff_file_entries()
	local list = {}
	for i, e in ipairs(state.entries) do
		if e.type == "file" then table.insert(list, { idx = i, entry = e }) end
	end
	return list
end

local function diff_cur_pos(list)
	for pos, fe in ipairs(list) do
		if fe.idx == diff_state.entry_idx then return pos end
	end
end

local function close_diff()
	if not diff_state.active then return end
	if diff_state.right_win and vim.api.nvim_win_is_valid(diff_state.right_win) then
		vim.api.nvim_win_call(diff_state.right_win, function() vim.cmd("diffoff") end)
		vim.wo[diff_state.right_win].signcolumn = "yes"
	end
	if diff_state.left_win and vim.api.nvim_win_is_valid(diff_state.left_win) then
		vim.api.nvim_win_close(diff_state.left_win, true)
	end
	diff_state.active    = false
	diff_state.left_win  = nil
	diff_state.right_win = nil
	diff_state.entry_idx = nil
	if base.is_valid(state) then
		vim.api.nvim_set_current_win(state.sidebar_win)
	end
end

local function get_orig_lines(entry)
	if entry.status == "?" then return nil end
	local path = entry.path
	local ref
	if entry.staged then
		ref = "HEAD:"
	else
		git_run({ "cat-file", "-e", ":0:" .. path })
		ref = vim.v.shell_error == 0 and ":0:" or "HEAD:"
	end
	local lines = git_run_lines({ "show", ref .. path })
	return vim.v.shell_error == 0 and lines or {}
end

local open_file_diff  -- forward declaration

local function set_nav_maps(buf)
	if not vim.api.nvim_buf_is_valid(buf) then return end
	local nav = { buffer = buf, nowait = true }
	vim.keymap.set("n", "]f", function()
		local list = diff_file_entries()
		local pos  = diff_cur_pos(list)
		if not pos or pos >= #list then return end
		open_file_diff(list[pos + 1].entry, list[pos + 1].idx)
	end, nav)
	vim.keymap.set("n", "[f", function()
		local list = diff_file_entries()
		local pos  = diff_cur_pos(list)
		if not pos or pos <= 1 then return end
		open_file_diff(list[pos - 1].entry, list[pos - 1].idx)
	end, nav)
end

open_file_diff = function(entry, entry_idx)
	if not entry.path or entry.path == "" then return end

	-- Save right_win before close_diff clears it; reuse it as target so
	-- find_target_win (which may return a stale nofile window) is bypassed.
	local prev_right = diff_state.active and diff_state.right_win or nil
	if diff_state.active then close_diff() end

	local win = (prev_right and vim.api.nvim_win_is_valid(prev_right) and prev_right)
		or base.find_target_win(state)
	if not win then return end

	-- Untracked files have no git history; diff against empty buffer so the
	-- full file content shows as "added".
	local orig_lines = entry.status == "?" and {} or get_orig_lines(entry)
	local label      = entry.status == "?" and "[new file]"
		or (entry.staged and "[HEAD]" or "[index]")

	vim.api.nvim_set_current_win(win)
	vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
	local right_win = vim.api.nvim_get_current_win()
	local right_buf = vim.api.nvim_get_current_buf()

	local orig_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[orig_buf].buftype   = "nofile"
	vim.bo[orig_buf].bufhidden = "wipe"
	vim.bo[orig_buf].swapfile  = false
	local ft = vim.filetype.match({ filename = entry.path }) or ""
	if ft ~= "" then pcall(function() vim.bo[orig_buf].filetype = ft end) end
	vim.api.nvim_buf_set_name(orig_buf, entry.path .. " " .. label)
	vim.api.nvim_buf_set_lines(orig_buf, 0, -1, false, orig_lines or {})
	vim.bo[orig_buf].modifiable = false

	vim.cmd("leftabove vsplit")
	local left_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(left_win, orig_buf)

	local function apply_diff_winopts(w)
		vim.wo[w].foldlevel  = 999
		vim.wo[w].wrap       = false
		vim.wo[w].signcolumn = "no"
	end

	vim.api.nvim_win_call(left_win,  function() vim.cmd("diffthis") end)
	vim.api.nvim_win_call(right_win, function() vim.cmd("diffthis") end)
	apply_diff_winopts(left_win)
	apply_diff_winopts(right_win)

	diff_state.active    = true
	diff_state.left_win  = left_win
	diff_state.right_win = right_win
	diff_state.entry_idx = entry_idx

	-- Sync sidebar cursor to the current file without stealing focus
	if base.is_valid(state) then
		vim.api.nvim_win_set_cursor(state.sidebar_win, { entry_idx, 0 })
	end

	vim.api.nvim_set_current_win(right_win)

	local kopts = { buffer = right_buf, nowait = true }

	vim.keymap.set("n", "q", close_diff, kopts)

	vim.keymap.set("n", "-", function()
		local e = state.entries[diff_state.entry_idx]
		if not e or e.type ~= "file" then return end
		if e.staged then
			git_run({ "restore", "--staged", e.path })
		else
			git_run({ "add", e.path })
		end
		refresh()
	end, kopts)

	-- Set on orig_buf immediately (nofile — no plugin will override it).
	set_nav_maps(orig_buf)

	-- Schedule for right_buf so we win over synchronous FileType/ftplugin autocmds.
	-- Also re-apply on LspAttach since treesitter-textobjects maps ]f asynchronously.
	vim.schedule(function() set_nav_maps(right_buf) end)
	vim.api.nvim_create_autocmd("LspAttach", {
		buffer   = right_buf,
		once     = false,
		callback = function() vim.schedule(function() set_nav_maps(right_buf) end) end,
	})
end

-- ── Keymaps ──

local function setup_keymaps()
	local opts = { buffer = state.sidebar_buf, nowait = true }

	vim.keymap.set("n", "<CR>", function()
		local entry, line = cursor_entry()
		if not entry then return end
		if entry.type == "file" then
			open_file_diff(entry, line)
		elseif entry.type == "branch" then
			if entry.is_current then
				vim.notify("Already on branch '" .. entry.name .. "'", vim.log.levels.INFO)
				return
			end
			local choice = vim.fn.confirm("Checkout '" .. entry.name .. "'?", "&Yes\n&No", 1)
			if choice ~= 1 then return end
			git_async({ "checkout", entry.name }, "Checkout " .. entry.name)
		elseif entry.type == "stash" then
			local choice = vim.fn.confirm("Pop '" .. entry.ref .. "'? (apply + drop)", "&Yes\n&No", 1)
			if choice ~= 1 then return end
			git_async({ "stash", "pop", entry.ref }, "Stash pop")
		end
	end, opts)

	-- Stage / Unstage single file
	vim.keymap.set("n", "s", function()
		local entry = cursor_entry()
		if not entry or entry.type ~= "file" or entry.staged ~= false then return end
		git_run({ "add", entry.path })
		refresh()
	end, opts)

	vim.keymap.set("n", "u", function()
		local entry = cursor_entry()
		if not entry or entry.type ~= "file" or entry.staged ~= true then return end
		git_run({ "restore", "--staged", entry.path })
		refresh()
	end, opts)

	-- Stage / Unstage all
	vim.keymap.set("n", "S", function()
		git_run({ "add", "-A" })
		refresh()
	end, opts)

	vim.keymap.set("n", "U", function()
		local staged, _ = parse_status()
		if #staged == 0 then
			vim.notify("No staged changes to unstage", vim.log.levels.WARN)
			return
		end
		git_run({ "restore", "--staged", "." })
		refresh()
	end, opts)

	-- Stash actions
	vim.keymap.set("n", "a", function()
		local entry = cursor_entry()
		if not entry or entry.type ~= "stash" then return end
		local choice = vim.fn.confirm("Apply '" .. entry.ref .. "' (keep in stash list)?", "&Yes\n&No", 1)
		if choice ~= 1 then return end
		git_async({ "stash", "apply", entry.ref }, "Stash apply")
	end, opts)

	vim.keymap.set("n", "d", function()
		local entry = cursor_entry()
		if not entry or entry.type ~= "stash" then return end
		local choice = vim.fn.confirm("Drop '" .. entry.ref .. "'?", "&Yes\n&No", 2)
		if choice ~= 1 then return end
		git_async({ "stash", "drop", entry.ref }, "Stash drop")
	end, opts)

	-- Discard
	vim.keymap.set("n", "x", function()
		local entry = cursor_entry()
		if not entry or entry.type ~= "file" or entry.staged ~= false then return end
		local label  = entry.status == "?" and "Delete untracked file" or "Discard changes to"
		local choice = vim.fn.confirm(label .. " " .. entry.path .. "?", "&Yes\n&No", 2)
		if choice ~= 1 then return end
		if entry.status == "?" then
			git_run({ "clean", "-f", "--", entry.path })
		else
			git_run({ "restore", entry.path })
		end
		refresh()
	end, opts)

	vim.keymap.set("n", "X", function()
		local choice = vim.fn.confirm("Discard ALL unstaged changes (and delete untracked)?", "&Yes\n&No", 2)
		if choice ~= 1 then return end
		git_run({ "restore", "." })
		git_run({ "clean", "-fd", "." })
		refresh()
	end, opts)

	-- Commit
	vim.keymap.set("n", "c", function()
		local staged, _ = parse_status()
		if #staged == 0 then
			vim.notify("No staged changes to commit", vim.log.levels.WARN)
			return
		end
		open_commit_buf(false)
	end, opts)
	vim.keymap.set("n", "C", function()
		local has_commits = git_run({ "rev-parse", "HEAD" }):match("^%x+")
		if not has_commits then
			vim.notify("No commits to amend", vim.log.levels.WARN)
			return
		end
		open_commit_buf(true)
	end, opts)

	-- Remote
	vim.keymap.set("n", "P", function() git_async({ "push"  }, "Push")  end, opts)
	vim.keymap.set("n", "p", function() git_async({ "pull"  }, "Pull")  end, opts)
	vim.keymap.set("n", "F", function() git_async({ "fetch" }, "Fetch") end, opts)

	vim.keymap.set("n", "z", function()
		local entry = cursor_entry()
		if not entry or entry.type ~= "header" or not entry.section then return end
		fold_state[entry.section] = not fold_state[entry.section]
		render()
	end, opts)

	vim.keymap.set("n", "r", function() render() end, opts)
	vim.keymap.set("n", "?", open_help, opts)

	-- Navigate between file diffs from the sidebar (safe from filetype overrides)
	vim.keymap.set("n", "]f", function()
		local list = diff_file_entries()
		local pos  = diff_cur_pos(list)
		if diff_state.active and pos and pos < #list then
			local nxt = list[pos + 1]
			open_file_diff(nxt.entry, nxt.idx)
		end
	end, opts)

	vim.keymap.set("n", "[f", function()
		local list = diff_file_entries()
		local pos  = diff_cur_pos(list)
		if diff_state.active and pos and pos > 1 then
			local prv = list[pos - 1]
			open_file_diff(prv.entry, prv.idx)
		end
	end, opts)

	base.add_common_keymaps(state, M.close)
end

-- ── Public API ──

function M.open()
	local k, h = "%#GitSidebarKey#", "%#GitSidebarHintDesc#"
	base.open_win(state, {
		filetype   = "GitSidebar",
		statusline = " "
			.. k.."s"..h..":stage  "..k.."u"..h..":unstage  "
			.. k.."c"..h..":commit  "..k.."<CR>"..h..":diff  "
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
	callback = function()
		_count_cache = nil
		vim.schedule(function()
			require("user.core.sidebar").refresh_tabbar()
		end)
	end,
})

vim.schedule(function()
	require("user.core.sidebar").register({
		id        = "git",
		label     = "Git",
		icon      = "󰊢 (G)",
		open      = M.open,
		close     = M.close,
		is_open   = function() return base.is_valid(state) end,
		get_win   = function() return state.sidebar_win end,
		get_count = M.get_count,
	})
end)

return M

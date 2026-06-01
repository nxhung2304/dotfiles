local M = {}
local base = require("user.core.sidebar.base")

local ns = vim.api.nvim_create_namespace("MarksSidebar")

base.setup_hl({
	{ "MarksSidebarIndex",  { link = "Function",  default = true } },
	{ "MarksSidebarFile",   { link = "Directory", default = true } },
	{ "MarksSidebarActive", { link = "Search",    default = true } },
	{ "MarksSidebarKey",    { link = "Function",  default = true } },
	{ "MarksSidebarHint",   { link = "Comment",   default = true } },
})

-- Per-project marks: { path, lnum }
local marks    = {}
local _cwd     = nil   -- project root the current marks belong to
local _nav_idx = 0     -- last jumped-to index for <C-n>/<C-p>

local state = base.new_state("MarksSidebar")

-- ── persistence ────────────────────────────────────────────────────────────

local function save()
	base.save_project_data("marks_sidebar", marks, _cwd)
end

local function load(cwd)
	_cwd  = cwd or vim.fn.getcwd()
	marks = base.load_project_data("marks_sidebar", _cwd) or {}
end

-- ── helpers ─────────────────────────────────────────────────────────────────

local function current_file()
	local win = base.find_target_win(state)
	if not win then return nil end
	local buf  = vim.api.nvim_win_get_buf(win)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" or vim.bo[buf].buftype ~= "" then return nil end
	return vim.fn.fnamemodify(name, ":p")
end

local function index_of(path)
	for i, m in ipairs(marks) do
		if m.path == path then return i end
	end
	return nil
end

-- ── public API ──────────────────────────────────────────────────────────────

function M.add(path)
	local win  = base.find_target_win(state)
	local lnum = win and vim.api.nvim_win_get_cursor(win)[1] or 1
	path = path or current_file()
	if not path then
		vim.notify("Marks: no file to mark", vim.log.levels.WARN)
		return
	end
	local existing = index_of(path)
	if existing then
		if marks[existing].lnum == lnum then return end
		marks[existing].lnum = lnum
		save()
		vim.notify("Marks: updated [" .. existing .. "] " .. vim.fn.fnamemodify(path, ":~:.") .. ":" .. lnum)
		M.render()
		return
	end
	table.insert(marks, { path = path, lnum = lnum })
	save()
	vim.notify("Marks: added [" .. #marks .. "] " .. vim.fn.fnamemodify(path, ":~:.") .. ":" .. lnum)
	M.render()
end

function M.remove(path)
	local idx = index_of(path)
	if idx then
		table.remove(marks, idx)
		save()
		vim.notify("Marks: removed " .. vim.fn.fnamemodify(path, ":~:."))
		M.render()
	end
end

function M.jump(idx)
	local mark = marks[idx]
	if not mark then
		vim.notify("Marks: no mark at [" .. idx .. "]", vim.log.levels.WARN)
		return
	end
	_nav_idx = idx
	local win = base.find_target_win(state)
	if not win then
		vim.cmd("edit " .. vim.fn.fnameescape(mark.path))
		return
	end
	vim.api.nvim_set_current_win(win)
	vim.cmd("edit " .. vim.fn.fnameescape(mark.path))
	local line_count = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win))
	vim.api.nvim_win_set_cursor(win, { math.min(mark.lnum, line_count), 0 })
	vim.cmd("normal! zz")

	vim.schedule(function()
		if not base.is_valid(state) then
			require("user.core.sidebar").switch("marks", { focus = false })
		end
		M.render()
		if base.is_valid(state) then
			vim.api.nvim_win_set_cursor(state.sidebar_win, { idx, 0 })
		end
	end)
end

function M.nav(dir)
	if #marks == 0 then
		vim.notify("Marks: no marks", vim.log.levels.WARN)
		return
	end
	local idx = ((_nav_idx - 1 + dir) % #marks) + 1
	M.jump(idx)
end

-- ── render ───────────────────────────────────────────────────────────────────

function M.render()
	if not base.is_valid(state) then return end

	local active = current_file()
	local lines, entries = {}, {}

	if #marks == 0 then
		table.insert(lines,   "  no marks yet")
		table.insert(entries, { type = "hint" })
		table.insert(lines,   "")
		table.insert(entries, { type = "empty" })
		table.insert(lines,   "  <leader>a  add current file")
		table.insert(entries, { type = "hint" })
	else
		for i, mark in ipairs(marks) do
			local rel     = vim.fn.fnamemodify(mark.path, ":~:.")
			local parts   = vim.split(rel, "/", { plain = true })
			local display = #parts <= 4 and rel
				or ("…/" .. parts[#parts - 2] .. "/" .. parts[#parts - 1] .. "/" .. parts[#parts])
			local is_active = (mark.path == active)
			local prefix    = string.format(" [%d] ", i)
			table.insert(lines,   prefix .. display .. ":" .. mark.lnum)
			table.insert(entries, {
				type       = "mark",
				path       = mark.path,
				idx        = i,
				is_active  = is_active,
				prefix_len = #prefix,
				disp_len   = #prefix + #display,
			})
		end
	end

	state.entries = entries
	base.set_lines(state, lines)

	vim.api.nvim_buf_clear_namespace(state.sidebar_buf, ns, 0, -1)
	for i, entry in ipairs(entries) do
		local row = i - 1
		if entry.type == "mark" then
			if entry.is_active then
				vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "MarksSidebarActive", row, 0, -1)
			else
				vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "MarksSidebarIndex", row, 0,               entry.prefix_len)
				vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "MarksSidebarFile",  row, entry.prefix_len, entry.disp_len)
				vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "MarksSidebarHint",  row, entry.disp_len,  -1)
			end
		elseif entry.type == "hint" then
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "MarksSidebarHint", row, 0, -1)
		end
	end

	require("user.core.sidebar").set_tabbar(state.sidebar_win)
end

-- ── keymaps / open / close ──────────────────────────────────────────────────

local function move_mark(from, to)
	if from < 1 or from > #marks or to < 1 or to > #marks then return end
	local item = table.remove(marks, from)
	table.insert(marks, to, item)
	save()
	M.render()
	vim.api.nvim_win_set_cursor(state.sidebar_win, { to, 0 })
end

local function setup_keymaps()
	local opts = { buffer = state.sidebar_buf, nowait = true }

	vim.keymap.set("n", "<CR>", function()
		local entry = base.cursor_entry(state)
		if not entry or entry.type ~= "mark" then return end
		M.jump(entry.idx)
	end, opts)

	vim.keymap.set("n", "a", function() M.add() end, opts)

	vim.keymap.set("n", "d", function()
		local entry = base.cursor_entry(state)
		if not entry or entry.type ~= "mark" then return end
		M.remove(entry.path)
	end, opts)

	vim.keymap.set("n", "c", function()
		if #marks == 0 then return end
		vim.ui.input({ prompt = "Clear all marks? (y/N): " }, function(input)
			if input and input:lower() == "y" then
				marks = {}
				save()
				vim.notify("Marks: cleared all")
				M.render()
			end
		end)
	end, opts)

	vim.keymap.set("n", "J", function()
		local entry = base.cursor_entry(state)
		if not entry or entry.type ~= "mark" then return end
		move_mark(entry.idx, entry.idx + 1)
	end, opts)

	vim.keymap.set("n", "K", function()
		local entry = base.cursor_entry(state)
		if not entry or entry.type ~= "mark" then return end
		move_mark(entry.idx, entry.idx - 1)
	end, opts)

	for i = 1, 9 do
		vim.keymap.set("n", tostring(i), function() M.jump(i) end, opts)
	end

	base.add_common_keymaps(state, M.close)
end

function M.open()
	local k, h = "%#MarksSidebarKey#", "%#MarksSidebarHint#"
	base.open_win(state, {
		filetype   = "MarksSidebar",
		statusline = " "
			.. k .. "a" .. h .. ":add  "
			.. k .. "d" .. h .. ":remove  "
			.. k .. "c" .. h .. ":clear all  "
			.. k .. "J/K" .. h .. ":reorder  "
			.. k .. "1-9" .. h .. ":jump",
		cursorline = true,
	})

	setup_keymaps()
	M.render()
	vim.api.nvim_set_current_win(state.sidebar_win)

	vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
		group    = state.augroup,
		callback = function()
			if base.is_valid(state) then vim.schedule(M.render) end
		end,
	})

	base.on_win_closed(state, function() state.entries = {} end)
end

M.close = base.make_close(state)

-- ── project switching ────────────────────────────────────────────────────────

-- Reload marks when the cwd changes (e.g. :cd, direnv, oil.nvim)
vim.api.nvim_create_autocmd("DirChanged", {
	group    = vim.api.nvim_create_augroup("MarksSidebarProject", { clear = true }),
	callback = function()
		local new_cwd = vim.fn.getcwd()
		if new_cwd == _cwd then return end
		load(new_cwd)
		if base.is_valid(state) then vim.schedule(M.render) end
	end,
})

-- ── global keymaps ───────────────────────────────────────────────────────────

vim.schedule(function()
	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
	end

	map("<leader>a",  function() M.add() end, "Marks: add current file")
	map("<leader>md", function()
		local path = current_file()
		if path then M.remove(path) end
	end, "Marks: remove current file")
	map("<C-n>", function() M.nav(1)  end, "Marks: next")
	map("<C-p>", function() M.nav(-1) end, "Marks: prev")
end)

-- ── register & initial load ──────────────────────────────────────────────────

load()   -- load marks for the cwd at startup

vim.schedule(function()
	require("user.core.sidebar").register({
		id        = "marks",
		label     = "Marks",
		icon      = "󰃀 (M)",
		open      = M.open,
		close     = M.close,
		is_open   = function() return base.is_valid(state) end,
		get_win   = function() return state.sidebar_win end,
		get_count = function() return #marks > 0 and #marks or nil end,
	})
end)

return M

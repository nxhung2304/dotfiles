local M = {}
local base = require("user.core.sidebar.base")

local ns = vim.api.nvim_create_namespace("SearchSidebar")

base.setup_hl({
	{ "SearchSidebarLabel",    { link = "Function",  default = true } },
	{ "SearchSidebarFile",     { link = "Directory", default = true } },
	{ "SearchSidebarCount",    { link = "Comment",   default = true } },
	{ "SearchSidebarMatch",    { link = "Search",    default = true } },
	{ "SearchSidebarKey",      { link = "Function",  default = true } },
	{ "SearchSidebarHint",     { link = "Comment",   default = true } },
	{ "SearchSidebarExcluded", { link = "Comment",   default = true } },
	{ "SearchSidebarHistory",  { link = "Special",   default = true } },
})

-- persists across open/close AND across sessions (per-project)
local history     = {}   -- list of past query strings, newest at end
local history_idx = 0    -- 0 = not browsing; N = pointing at history[N]

local function save_history()
	base.save_project_data("search_sidebar", history)
end

local function load_history()
	history = base.load_project_data("search_sidebar") or {}
end

load_history()

local state = vim.tbl_extend("force", base.new_state("SearchSidebar"), {
	query        = "",
	replace      = "",
	include      = "",
	exclude      = "",
	folder       = "",
	hidden       = true,
	results      = {},   -- { path, lnum, col, text }
	collapsed    = {},   -- path -> true when folded
	excluded     = {},   -- key -> true: path for whole-file, path.."\0"..lnum for single result
	excl_history = {},   -- undo stack of excluded snapshots
})

local FIELDS = {
	{ key = "query",   label = "Search ", prompt = "Search: " },
	{ key = "replace", label = "Replace", prompt = "Replace: " },
	{ key = "include", label = "Include", prompt = "Include (*.lua,*.ts): " },
	{ key = "exclude", label = "Exclude", prompt = "Exclude (*.min.js,dist/): " },
	{ key = "folder",  label = "Folder ", prompt = "Folder (relative to cwd): " },
}

local LABEL_W = 8

local function run_search()
	if state.query == "" then state.results = {}; return end

	local args = {
		"rg", "--line-number", "--column",
		"--no-heading", "--color=never", "--smart-case",
		"--max-count=200",
	}
	if state.hidden then table.insert(args, "--hidden") end

	for pat in state.include:gmatch("[^,]+") do
		pat = pat:match("^%s*(.-)%s*$")
		if pat ~= "" then
			table.insert(args, "--glob"); table.insert(args, vim.fn.shellescape(pat))
		end
	end

	for pat in state.exclude:gmatch("[^,]+") do
		pat = pat:match("^%s*(.-)%s*$")
		if pat ~= "" then
			table.insert(args, "--glob"); table.insert(args, vim.fn.shellescape("!" .. pat))
		end
	end

	table.insert(args, "--")
	table.insert(args, vim.fn.shellescape(state.query))

	local dir = state.folder ~= "" and (vim.fn.getcwd() .. "/" .. state.folder) or vim.fn.getcwd()
	table.insert(args, vim.fn.shellescape(dir))

	local raw     = vim.fn.systemlist(table.concat(args, " "))
	local results = {}
	for _, line in ipairs(raw) do
		local path, lnum, col, text = line:match("^(.-)%:(%d+)%:(%d+)%:(.*)$")
		if path then
			table.insert(results, { path = path, lnum = tonumber(lnum), col = tonumber(col), text = text })
		end
	end
	state.results  = results
	state.collapsed = {}
	state.excluded  = {}

	-- push to history (deduplicate consecutive identical queries)
	if state.query ~= "" and history[#history] ~= state.query then
		table.insert(history, state.query)
		if #history > 3 then table.remove(history, 1) end
		save_history()
	end
	history_idx = 0
end

-- Find first occurrence of query in text, respecting smart-case.
-- Returns byte start, byte end (1-indexed), or nil.
local function find_match(text, query)
	if query == "" then return nil end
	local has_upper = query:match("[A-Z]")
	if has_upper then
		local s, e = text:find(query, 1, true)
		return s, e
	else
		local s, e = text:lower():find(query:lower(), 1, true)
		return s, e
	end
end

-- Apply query→replace on a single line (respects smart-case).
local function do_text_replace(text, query, replace)
	local has_upper = query:match("[A-Z]")
	local repl = replace:gsub("%%", "%%%%")
	if has_upper then
		return (text:gsub(vim.pesc(query), repl))
	end
	local out, i = {}, 1
	local low_t, low_q, qlen = text:lower(), query:lower(), #query
	while i <= #text do
		local s = low_t:find(low_q, i, true)
		if s then
			out[#out+1] = text:sub(i, s - 1)
			out[#out+1] = replace
			i = s + qlen
		else
			out[#out+1] = text:sub(i); break
		end
	end
	return table.concat(out)
end

local function show_replace_preview(on_confirm)
	local active = {}
	for _, r in ipairs(state.results) do
		local res_key = r.path .. "\0" .. r.lnum
		if not state.excluded[r.path] and not state.excluded[res_key] then
			table.insert(active, r)
		end
	end

	local file_order, by_file = {}, {}
	for _, r in ipairs(active) do
		if not by_file[r.path] then
			by_file[r.path] = {}
			table.insert(file_order, r.path)
		end
		table.insert(by_file[r.path], r)
	end

	local lines, meta_hls, word_hls = {}, {}, {}
	local function add(line, hl)
		lines[#lines+1] = line
		if hl then meta_hls[#meta_hls+1] = { row = #lines - 1, hl = hl } end
	end

	add(string.format("  %d replacements in %d files", #active, #file_order), "Comment")
	add("  y / <CR>  confirm        q / <Esc>  cancel", "Comment")
	add(string.rep("─", 64))

	-- "  %4d - " → 2 + 4 + 3 = 9 bytes prefix; sign '-'/'+' is at byte 7 (0-indexed)
	local PREFIX   = 9
	local SIGN_COL = 7

	for _, path in ipairs(file_order) do
		add("")
		add(" " .. vim.fn.fnamemodify(path, ":~:."), "Directory")
		for _, r in ipairs(by_file[path]) do
			local orig     = r.text:match("^%s*(.-)%s*$") or ""
			local replaced = do_text_replace(r.text, state.query, state.replace)
			replaced = replaced:match("^%s*(.-)%s*$") or ""

			-- removed line: plain text + sign + keyword highlight
			add(string.format("  %4d - %s", r.lnum, orig))
			local row_del = #lines - 1
			word_hls[#word_hls+1] = { row = row_del, s = SIGN_COL, e = SIGN_COL + 1, hl = "DiffDelete" }
			local ms, me = find_match(orig, state.query)
			if ms then
				word_hls[#word_hls+1] = { row = row_del, s = PREFIX + ms - 1, e = PREFIX + me, hl = "DiffDelete" }
			end

			-- added line: plain text + sign + replacement highlight
			add(string.format("  %4d + %s", r.lnum, replaced))
			local row_add = #lines - 1
			word_hls[#word_hls+1] = { row = row_add, s = SIGN_COL, e = SIGN_COL + 1, hl = "DiffAdd" }
			local rs, re = replaced:find(state.replace, 1, true)
			if rs then
				word_hls[#word_hls+1] = { row = row_add, s = PREFIX + rs - 1, e = PREFIX + re, hl = "DiffAdd" }
			end
		end
	end

	local width  = math.min(100, math.max(64, vim.o.columns - 8))
	local height = math.min(math.max(10, #lines), vim.o.lines - 6)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	local ns_p = vim.api.nvim_create_namespace("SearchSidebarPreview")
	for _, info in ipairs(meta_hls) do
		vim.api.nvim_buf_add_highlight(buf, ns_p, info.hl, info.row, 0, -1)
	end
	for _, info in ipairs(word_hls) do
		vim.api.nvim_buf_add_highlight(buf, ns_p, info.hl, info.row, info.s, info.e)
	end

	local win = vim.api.nvim_open_win(buf, true, {
		relative  = "editor",
		width     = width,
		height    = height,
		row       = math.floor((vim.o.lines - height) / 2),
		col       = math.floor((vim.o.columns - width) / 2),
		style     = "minimal",
		border    = "rounded",
		title     = string.format(" Replace '%s' → '%s' ", state.query, state.replace),
		title_pos = "center",
	})
	vim.wo[win].cursorline = true

	local function close_preview()
		if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
	end
	local function confirm() close_preview(); on_confirm() end

	for _, k in ipairs({ "y", "<CR>" }) do
		vim.keymap.set("n", k, confirm, { buffer = buf, nowait = true })
	end
	for _, k in ipairs({ "n", "q", "<Esc>" }) do
		vim.keymap.set("n", k, close_preview, { buffer = buf, nowait = true })
	end
end

local function render()
	if not base.is_valid(state) then return end

	local lines   = {}
	local entries = {}
	-- per-result: { row (0-indexed), match_s, match_e } for keyword hl
	local match_hls = {}

	-- Form section
	for _, f in ipairs(FIELDS) do
		table.insert(lines,   f.label .. ": " .. state[f.key])
		table.insert(entries, { type = "field", key = f.key })
	end
	table.insert(lines,   "Hidden : " .. (state.hidden and "on" or "off"))
	table.insert(entries, { type = "toggle", key = "hidden" })

	-- Separator
	table.insert(lines,   string.rep("─", 48))
	table.insert(entries, { type = "sep" })

	-- Results
	if state.query == "" then
		table.insert(lines,   "  press s to enter a search query")
		table.insert(entries, { type = "hint" })
		if #history > 0 then
			table.insert(lines,   "")
			table.insert(entries, { type = "sep" })
			table.insert(lines,   "  Recent:")
			table.insert(entries, { type = "hint" })
			for i = #history, math.max(1, #history - 2), -1 do
				table.insert(lines,   "    " .. history[i])
				table.insert(entries, { type = "history", query = history[i] })
			end
		end
	elseif #state.results == 0 then
		table.insert(lines,   "  no results")
		table.insert(entries, { type = "hint" })
	else
		local file_order = {}
		local by_file    = {}
		for _, r in ipairs(state.results) do
			if not by_file[r.path] then
				by_file[r.path] = {}
				table.insert(file_order, r.path)
			end
			table.insert(by_file[r.path], r)
		end

		local suffix = #state.results >= 200 and "+" or ""
		table.insert(lines,   string.format("  %d%s matches in %d files", #state.results, suffix, #file_order))
		table.insert(entries, { type = "summary" })

		local win_w = vim.api.nvim_win_get_width(state.sidebar_win)

		for _, path in ipairs(file_order) do
			local collapsed  = state.collapsed[path]
			local file_excl  = state.excluded[path]
			local count      = #by_file[path]
			local rel        = vim.fn.fnamemodify(path, ":~:.")
			local fold_icon  = collapsed and "▶ " or "▼ "
			local count_str  = collapsed and (" (" .. count .. ")") or ""
			local excl_mark  = file_excl and " 󰅗" or ""

			table.insert(lines,   fold_icon .. rel .. count_str .. excl_mark)
			table.insert(entries, {
				type = "file", path = path, collapsed = collapsed,
				excl_key = path, excluded = file_excl,
			})

			if not collapsed then
				for _, r in ipairs(by_file[path]) do
					local res_key  = path .. "\0" .. r.lnum
					local res_excl = file_excl or state.excluded[res_key]

					local trimmed = r.text:match("^%s*(.-)%s*$") or ""
					local max_txt = math.max(20, win_w - 10)
					local truncated = false
					if #trimmed > max_txt then
						trimmed   = trimmed:sub(1, max_txt - 1) .. "…"
						truncated = true
					end

					local lnum_str  = tostring(r.lnum)
					local prefix    = "   " .. lnum_str .. ": "
					local excl_sfx  = res_excl and " 󰅗" or ""
					local line_text = prefix .. trimmed .. excl_sfx

					table.insert(lines,   line_text)
					table.insert(entries, {
						type = "result", path = r.path, lnum = r.lnum, col = r.col,
						prefix_len = #prefix, truncated = truncated,
						excl_key = res_key, excluded = res_excl,
					})

					if not res_excl then
						local ms, me = find_match(trimmed, state.query)
						if ms then
							table.insert(match_hls, {
								row = #lines - 1,
								s   = #prefix + ms - 1,
								e   = #prefix + me,
							})
						end
					end
				end
			end
		end
	end

	state.entries = entries
	base.set_lines(state, lines)

	-- Highlights
	vim.api.nvim_buf_clear_namespace(state.sidebar_buf, ns, 0, -1)
	for i, entry in ipairs(entries) do
		local row = i - 1
		if entry.type == "field" or entry.type == "toggle" then
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "SearchSidebarLabel", row, 0, LABEL_W)
		elseif entry.type == "file" then
			local hl = entry.excluded and "SearchSidebarExcluded" or "SearchSidebarFile"
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, hl, row, 0, -1)
		elseif entry.type == "history" then
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "SearchSidebarHistory", row, 0, -1)
		elseif entry.type == "summary" then
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "SearchSidebarCount", row, 0, -1)
		elseif entry.type == "result" then
			if entry.excluded then
				vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "SearchSidebarExcluded", row, 0, -1)
			else
				vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "SearchSidebarCount", row, 0, entry.prefix_len)
			end
		end
	end

	-- Keyword match highlights (on top of result lines)
	for _, hl in ipairs(match_hls) do
		vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "SearchSidebarMatch", hl.row, hl.s, hl.e)
	end

	require("user.core.sidebar").set_tabbar(state.sidebar_win)
end

local function scroll_to_results()
	if not base.is_valid(state) then return end
	for i, entry in ipairs(state.entries) do
		if entry.type == "summary" or entry.type == "file" or entry.type == "hint" then
			vim.api.nvim_win_set_cursor(state.sidebar_win, { i, 0 })
			return
		end
	end
end

-- Toggle fold for the file that owns the entry at the current cursor line.
local function toggle_fold_at_cursor()
	local entry = base.cursor_entry(state)
	if not entry then return end
	local path = entry.path
	if path then
		state.collapsed[path] = not state.collapsed[path] or nil
		render()
	end
end

local function jump_to(path, lnum, col)
	local win = base.find_target_win(state)
	if not win then return end
	vim.api.nvim_set_current_win(win)
	vim.cmd("edit " .. vim.fn.fnameescape(path))
	if lnum then
		vim.api.nvim_win_set_cursor(win, { lnum, math.max(0, (col or 1) - 1) })
		vim.cmd("normal! zz")
	end
end

local function do_replace()
	if state.query == "" or state.replace == "" then
		vim.notify("SearchSidebar: set both Search and Replace first", vim.log.levels.WARN)
		return
	end
	if #state.results == 0 then
		vim.notify("SearchSidebar: run a search first", vim.log.levels.WARN)
		return
	end

	-- Collect only non-excluded results
	local active = {}
	for _, r in ipairs(state.results) do
		local res_key = r.path .. "\0" .. r.lnum
		if not state.excluded[r.path] and not state.excluded[res_key] then
			table.insert(active, r)
		end
	end
	if #active == 0 then
		vim.notify("SearchSidebar: all results are excluded", vim.log.levels.WARN)
		return
	end

	show_replace_preview(function()
		local files = {}
		for _, r in ipairs(active) do files[r.path] = true end
		local file_list = vim.tbl_keys(files)

		local escaped_q = vim.fn.escape(state.query,   "\\/.*~[]^$")
		local escaped_r = vim.fn.escape(state.replace, "\\/&~")
		local replaced, failed = 0, 0

		for _, path in ipairs(file_list) do
			local bufnr = vim.fn.bufadd(path)
			vim.fn.bufload(bufnr)
			local ok2, err = pcall(function()
				vim.api.nvim_buf_call(bufnr, function()
					vim.cmd(string.format("%%s/%s/%s/g", escaped_q, escaped_r))
					vim.cmd("write")
				end)
			end)
			if ok2 then replaced = replaced + 1
			else
				failed = failed + 1
				vim.notify("Error in " .. path .. ": " .. tostring(err), vim.log.levels.ERROR)
			end
		end

		vim.notify(string.format("Replaced in %d/%d files%s", replaced, #file_list,
			failed > 0 and (" (" .. failed .. " errors)") or ""))
		run_search()
		render()
		scroll_to_results()
	end)
end

local FIELD_KEY = { query = "s", replace = "r", include = "i", exclude = "e", folder = "f" }

local function open_help()
	local map = {
		{ "Fields", "" },
		{ "s",  "set search query" },
		{ "r",  "set replace text" },
		{ "i",  "set include globs  (*.lua,*.ts)" },
		{ "e",  "set exclude globs  (dist/)" },
		{ "f",  "set folder scope" },
		{ "H",  "toggle hidden files (dotfiles)" },
		{ "", "" },
		{ "Navigation", "" },
		{ "<CR>", "jump to result / edit field" },
		{ "[",  "older search history" },
		{ "]",  "newer search history" },
		{ "z",  "fold/unfold file" },
		{ "Z",  "fold/unfold all files" },
		{ "", "" },
		{ "Exclude", "" },
		{ "D",  "toggle exclude result/file" },
		{ "D",  "(visual) toggle exclude range" },
		{ "u",  "undo last exclude change" },
		{ "", "" },
		{ "Replace", "" },
		{ "R",  "preview diff then replace" },
		{ "", "" },
		{ "Misc", "" },
		{ "q",  "close sidebar" },
		{ "?",  "toggle this help" },
	}

	local width = 46
	local lines, hl_keys = {}, {}
	for _, row in ipairs(map) do
		local key, desc = row[1], row[2]
		if desc == "" then
			table.insert(lines, key == "" and "" or ("  " .. key))
			table.insert(hl_keys, key ~= "" and #lines or nil)
		else
			local pad = string.rep(" ", 8 - vim.fn.strdisplaywidth(key))
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
		title     = " Search Sidebar — Keys ",
		title_pos = "center",
	})

	local ns_h = vim.api.nvim_create_namespace("SearchSidebarHelpHl")
	for _, info in ipairs(hl_keys) do
		if type(info) == "table" then
			vim.api.nvim_buf_add_highlight(buf, ns_h, "SearchSidebarKey", info.line, 2, info.key_end)
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

	local function edit_field(key)
		return function()
			local f
			for _, ff in ipairs(FIELDS) do if ff.key == key then f = ff; break end end
			local ok, val = pcall(vim.fn.input, f.prompt, state[key])
			if not ok then return end  -- user pressed <Esc>
			state[key] = val
			-- defer so Neovim fully returns to normal mode before we block on rg
			vim.schedule(function()
				if not base.is_valid(state) then return end
				if key ~= "replace" then run_search() end
				render()
				if key ~= "replace" then scroll_to_results() end
				vim.api.nvim_set_current_win(state.sidebar_win)
			end)
		end
	end

	vim.keymap.set("n", "s", edit_field("query"),  opts)
	vim.keymap.set("n", "r", edit_field("replace"), opts)
	vim.keymap.set("n", "i", edit_field("include"), opts)
	vim.keymap.set("n", "e", edit_field("exclude"), opts)
	vim.keymap.set("n", "f", edit_field("folder"),  opts)

	vim.keymap.set("n", "H", function()
		state.hidden = not state.hidden
		run_search()
		render()
		scroll_to_results()
	end, opts)

	-- history navigation: [ = older, ] = newer
	local function nav_history(dir)
		if #history == 0 then return end
		local next_idx = history_idx + dir
		if next_idx < 1 then next_idx = 1 end
		if next_idx > #history then next_idx = #history end
		if next_idx == history_idx then return end
		history_idx = next_idx
		state.query = history[history_idx]
		run_search()
		render()
		scroll_to_results()
	end
	vim.keymap.set("n", "[", function() nav_history(-1) end, opts)
	vim.keymap.set("n", "]", function() nav_history(1)  end, opts)

	vim.keymap.set("n", "<CR>", function()
		local entry = base.cursor_entry(state)
		if not entry then return end
		if entry.type == "field" then
			local k = FIELD_KEY[entry.key]
			if k then vim.api.nvim_feedkeys(k, "n", true) end
		elseif entry.type == "toggle" then
			vim.api.nvim_feedkeys("H", "n", true)
		elseif entry.type == "history" then
			state.query = entry.query
			vim.schedule(function()
				if not base.is_valid(state) then return end
				run_search(); render(); scroll_to_results()
				vim.api.nvim_set_current_win(state.sidebar_win)
			end)
		elseif entry.type == "file" then
			toggle_fold_at_cursor()
		elseif entry.type == "result" then
			jump_to(entry.path, entry.lnum, entry.col)
		end
	end, opts)

	local function toggle_exclude_range(first, last)
		-- snapshot before mutating
		local snap = {}
		for k, v in pairs(state.excluded) do snap[k] = v end
		table.insert(state.excl_history, snap)

		for lnum = first, last do
			local entry = state.entries[lnum]
			if entry and entry.excl_key then
				state.excluded[entry.excl_key] = not state.excluded[entry.excl_key] or nil
			end
		end
		render()
	end

	-- D: toggle exclude for result or file under cursor
	vim.keymap.set("n", "D", function()
		local line = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
		toggle_exclude_range(line, line)
	end, opts)

	-- D in visual: toggle exclude for every line in selection
	vim.keymap.set("v", "D", function()
		local first = vim.fn.line("v")
		local last  = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
		if first > last then first, last = last, first end
		vim.api.nvim_feedkeys(
			vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
		toggle_exclude_range(first, last)
	end, opts)

	-- z: toggle fold for the file under/at cursor
	vim.keymap.set("n", "z", toggle_fold_at_cursor, opts)
	-- Za: collapse/expand all
	vim.keymap.set("n", "Z", function()
		-- if any expanded, collapse all; otherwise expand all
		local any_open = false
		for _, entry in ipairs(state.entries) do
			if entry.type == "file" and not entry.collapsed then any_open = true; break end
		end
		for _, entry in ipairs(state.entries) do
			if entry.type == "file" then
				state.collapsed[entry.path] = any_open or nil
			end
		end
		render()
	end, opts)

	-- u: undo last exclude/include operation
	vim.keymap.set("n", "u", function()
		local snap = table.remove(state.excl_history)
		if not snap then return end
		state.excluded = snap
		render()
	end, opts)

	vim.keymap.set("n", "R", do_replace, opts)
	vim.keymap.set("n", "?", open_help, opts)
	base.add_common_keymaps(state, M.close)
end

function M.open()
	local k, h = "%#SearchSidebarKey#", "%#SearchSidebarHint#"
	base.open_win(state, {
		filetype   = "SearchSidebar",
		statusline = " "
			.. k .. "s" .. h .. ":search  "
			.. k .. "R" .. h .. ":replace!  "
			.. k .. "H" .. h .. ":hidden  "
			.. k .. "?" .. h .. ":help",
		cursorline = true,
	})

	setup_keymaps()
	run_search()
	render()
	scroll_to_results()
	vim.api.nvim_set_current_win(state.sidebar_win)

	base.on_win_closed(state, function() state.entries = {} end)
end

M.close = base.make_close(state)

vim.schedule(function()
	require("user.core.sidebar").register({
		id      = "search",
		label   = "Search",
		icon    = "󰍉 (S)",
		open    = M.open,
		close   = M.close,
		is_open = function() return base.is_valid(state) end,
		get_win = function() return state.sidebar_win end,
	})
end)

return M

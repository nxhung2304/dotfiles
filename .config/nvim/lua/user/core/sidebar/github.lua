---@diagnostic disable: undefined-global
local M = {}
local base = require("user.core.sidebar.base")

local state = base.new_state("GithubSidebar")

local ns      = vim.api.nvim_create_namespace("GithubSidebarHl")
local _prs    = nil   -- nil=not loaded, false=error, table=loaded
local _issues = nil
local _loading = false

-- ── fetch ─────────────────────────────────────────────────────────────────────

local function load_data()
	if _loading then return end
	_loading = true
	_prs = nil; _issues = nil

	local Api  = require("snacks.gh.api")
	local done = 0
	local function on_done()
		done = done + 1
		if done == 2 then
			_loading = false
			if base.is_valid(state) then
				-- re-require to avoid upvalue issues after lazy load
				require("user.core.sidebar.github").render()
			end
		end
	end

	Api.list("pr", function(items)
		vim.schedule(function()
			_prs = items or false
			on_done()
		end)
	end, {})

	Api.list("issue", function(items)
		vim.schedule(function()
			_issues = items or false
			on_done()
		end)
	end, {})
end

-- ── render ────────────────────────────────────────────────────────────────────

local function status_hl(kind, status)
	local k = kind:sub(1, 1):upper() .. kind:sub(2)
	local s = status:sub(1, 1):upper() .. status:sub(2)
	return "SnacksGh" .. k .. s
end

function M.render()
	if not base.is_valid(state) then return end

	local lines   = {}
	local entries = {}

	if _loading then
		lines   = { "", "  Loading…" }
		entries = { { type = "empty" }, { type = "empty" } }
		state.entries = entries
		base.set_lines(state, lines)
		vim.api.nvim_buf_clear_namespace(state.sidebar_buf, ns, 0, -1)
		require("user.core.sidebar").set_tabbar(state.sidebar_win)
		return
	end

	local icons = Snacks.gh.config().icons

	local function add_section(header, items, kind)
		local icon_set = icons[kind] or {}
		if items == false then
			table.insert(lines,   header .. " (error)")
			table.insert(entries, { type = "header" })
			return
		end
		table.insert(lines,   header .. " (" .. #items .. ")")
		table.insert(entries, { type = "header" })
		if #items == 0 then
			table.insert(lines,   "  (none)")
			table.insert(entries, { type = "empty" })
			return
		end
		for _, item in ipairs(items) do
			local status    = item.status or "other"
			local icon      = icon_set[status] or icon_set.other or " "
			local num       = string.format("#%-4d", item.number)
			local title_str = item.title or ""
			local max_w     = 34
			if vim.fn.strdisplaywidth(title_str) > max_w then
				title_str = title_str:sub(1, max_w - 1) .. "…"
			end
			table.insert(lines,   "  " .. icon .. " " .. num .. " " .. title_str)
			table.insert(entries, { type = "item", kind = kind, status = status, item = item })
		end
	end

	add_section(icons.pr.open    .. " Pull Requests", _prs    or {}, "pr")
	table.insert(lines, ""); table.insert(entries, { type = "empty" })
	add_section(icons.issue.open .. " Issues",        _issues or {}, "issue")

	state.entries = entries
	base.set_lines(state, lines)

	vim.api.nvim_buf_clear_namespace(state.sidebar_buf, ns, 0, -1)
	for i, entry in ipairs(entries) do
		if entry.type == "header" then
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "Title", i - 1, 0, -1)
		elseif entry.type == "item" then
			-- icon (col 2-4) gets status colour
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, status_hl(entry.kind, entry.status), i - 1, 2, 5)
			-- #NNN
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "Number", i - 1, 6, 11)
		end
	end

	require("user.core.sidebar").set_tabbar(state.sidebar_win)
end

-- ── open item as read-only rendered buffer ────────────────────────────────────

local function open_item(entry)
	local Api    = require("snacks.gh.api")
	local Render = require("snacks.gh.render")
	local item   = entry.item

	local target = base.find_target_win(state)
	if target then vim.api.nvim_set_current_win(target) end

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)

	vim.bo[buf].buftype   = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile  = false
	vim.bo[buf].filetype  = "markdown"

	-- apply snacks gh window options (wrap, conceallevel, etc.)
	local gh_cfg = Snacks.gh.config()
	for k, v in pairs(gh_cfg.wo or {}) do
		pcall(vim.api.nvim_set_option_value, k, v, { win = win })
	end

	local function write(full_item)
		if not vim.api.nvim_buf_is_valid(buf) then return end
		vim.bo[buf].modifiable = true
		Render.render(buf, full_item, gh_cfg)
		vim.bo[buf].modifiable = false
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_set_cursor(win, { 1, 0 })
		end
	end

	-- show loading placeholder, then fetch full view with comments
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Loading…" })
	vim.bo[buf].modifiable = false

	Api.view(function(full_item, updated)
		vim.schedule(function()
			if updated then write(full_item) end
		end)
	end, item)

	vim.keymap.set("n", "T", function()
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		if #lines == 0 or (#lines == 1 and lines[1] == "Loading…") then
			vim.notify("Issue not loaded yet", vim.log.levels.WARN)
			return
		end

		-- open vertical split for translation
		vim.cmd("vsplit")
		local t_win = vim.api.nvim_get_current_win()
		local t_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(t_win, t_buf)
		vim.bo[t_buf].buftype   = "nofile"
		vim.bo[t_buf].bufhidden = "wipe"
		vim.bo[t_buf].swapfile  = false
		vim.bo[t_buf].filetype  = "markdown"
		vim.wo[t_win].wrap      = true
		vim.wo[t_win].number    = false

		vim.bo[t_buf].modifiable = true
		vim.api.nvim_buf_set_lines(t_buf, 0, -1, false, { "Translating…" })
		vim.bo[t_buf].modifiable = false

		local first_chunk = true
		vim.fn.jobstart({
			"gemini", "--model", "gemini-2.0-flash", "--prompt",
			"Translate the following GitHub issue/PR to Vietnamese. "
			.. "Preserve all markdown formatting exactly. "
			.. "Output only the translation, no commentary:\n\n"
			.. table.concat(lines, "\n"),
		}, {
			on_stdout = function(_, data)
				if not data then return end
				vim.schedule(function()
					if not vim.api.nvim_buf_is_valid(t_buf) then return end
					local chunks = vim.tbl_filter(function(l) return l ~= "" end, data)
					if #chunks == 0 then return end
					vim.bo[t_buf].modifiable = true
					if first_chunk then
						-- replace the "Translating…" placeholder
						vim.api.nvim_buf_set_lines(t_buf, 0, -1, false, chunks)
						first_chunk = false
					else
						local last = vim.api.nvim_buf_line_count(t_buf)
						vim.api.nvim_buf_set_lines(t_buf, last, last, false, chunks)
					end
					vim.bo[t_buf].modifiable = false
				end)
			end,
			on_exit = function(_, code)
				vim.schedule(function()
					if not vim.api.nvim_buf_is_valid(t_buf) then return end
					if code ~= 0 and first_chunk then
						vim.bo[t_buf].modifiable = true
						vim.api.nvim_buf_set_lines(t_buf, 0, -1, false, { "Translation failed." })
						vim.bo[t_buf].modifiable = false
					end
				end)
			end,
		})

		vim.keymap.set("n", "q", function()
			if vim.api.nvim_buf_is_valid(t_buf) then
				vim.api.nvim_buf_delete(t_buf, { force = true })
			end
		end, { buffer = t_buf, nowait = true })
	end, { buffer = buf, nowait = true })

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		if base.is_valid(state) then
			vim.api.nvim_set_current_win(state.sidebar_win)
		end
	end, { buffer = buf, nowait = true })
end

-- ── keymaps ───────────────────────────────────────────────────────────────────

local function setup_keymaps()
	local opts = { buffer = state.sidebar_buf, nowait = true }

	vim.keymap.set("n", "<CR>", function()
		local entry = base.cursor_entry(state)
		if not entry or entry.type ~= "item" then return end
		open_item(entry)
	end, opts)

	vim.keymap.set("n", "o", function()
		local entry = base.cursor_entry(state)
		if not entry or entry.type ~= "item" then return end
		local url = entry.item.url
		if not url or url == "" then return end
		local cmd = vim.fn.has("mac") == 1 and "open" or "xdg-open"
		vim.fn.jobstart({ cmd, url }, { detach = true })
	end, opts)

	vim.keymap.set("n", "r", function()
		_prs = nil; _issues = nil
		load_data()
	end, opts)

	base.add_common_keymaps(state, M.close)
end

-- ── public API ────────────────────────────────────────────────────────────────

function M.open()
	local k, h = "%#Function#", "%#Comment#"
	base.open_win(state, {
		filetype   = "GithubSidebar",
		statusline = " " .. k .. "<CR>" .. h .. ":view  " .. k .. "o" .. h .. ":browser  " .. k .. "r" .. h .. ":refresh  " .. k .. "q" .. h .. ":close",
		cursorline = true,
	})
	setup_keymaps()
	vim.api.nvim_set_current_win(state.sidebar_win)
	base.on_win_closed(state, function() state.entries = {} end)

	if _prs == nil and _issues == nil then
		load_data()
	else
		M.render()
	end
end

M.close = base.make_close(state)

-- ── register ──────────────────────────────────────────────────────────────────

vim.schedule(function()
	require("user.core.sidebar").register({
		id      = "github",
		label   = "GitHub",
		icon    = "",
		open    = M.open,
		close   = M.close,
		is_open = function() return base.is_valid(state) end,
		get_win = function() return state.sidebar_win end,
	})
end)

return M

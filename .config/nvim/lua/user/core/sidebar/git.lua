local M = {}
local base = require("user.core.sidebar.base")

local state = base.new_state("GitSidebar")

base.setup_hl({
	{ "GitSidebarStaged",        { link = "DiagnosticHint", default = true } },
	{ "GitSidebarBranchCurrent", { link = "Statement",      default = true } },
})

local _count_cache = nil

local function git_run_lines(args)
	return vim.fn.systemlist(vim.list_extend({ "git", "-C", vim.fn.getcwd() }, args))
end

local function parse_status()
	local raw = git_run_lines({ "status", "--porcelain" })
	local staged, unstaged = {}, {}
	for _, line in ipairs(raw) do
		if #line >= 4 then
			local x    = line:sub(1, 1)
			local y    = line:sub(2, 2)
			local path = line:sub(4)
			if path:sub(-1) == "/" then goto continue end
			if x ~= " " and x ~= "?" then
				table.insert(staged,   { status = x, path = path })
			end
			if y ~= " " then
				table.insert(unstaged, { status = y == "?" and "?" or y, path = path })
			end
			::continue::
		end
	end
	return staged, unstaged
end

function M.get_count()
	if _count_cache ~= nil then return _count_cache > 0 and _count_cache or nil end
	local lines = git_run_lines({ "status", "--porcelain" })
	_count_cache = #lines
	return _count_cache > 0 and _count_cache or nil
end

local ns = vim.api.nvim_create_namespace("GitSidebarHl")

local function format_path(path)
	local parts = vim.split(path, "/", { plain = true })
	if #parts <= 4 then return path end
	return "…/" .. parts[#parts - 2] .. "/" .. parts[#parts - 1] .. "/" .. parts[#parts]
end

local fold_state = { staged = false, changes = false, commits = false, branches = false }

-- ── Async helpers ──

local function git_async_lines(args, cb)
	local cwd    = vim.fn.getcwd()
	local result = {}
	vim.fn.jobstart(vim.list_extend({ "git", "-C", cwd }, args), {
		stdout_buffered = true,
		on_stdout = function(_, lines)
			for _, l in ipairs(lines or {}) do
				if l ~= "" then table.insert(result, l) end
			end
		end,
		on_exit = function() vim.schedule(function() cb(result) end) end,
	})
end

-- ── Render ──

local render

local function apply_highlights(entries)
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
		elseif entry.type == "branch" and entry.is_current then
			vim.api.nvim_buf_add_highlight(state.sidebar_buf, ns, "GitSidebarBranchCurrent", i - 1, 0, -1)
		end
	end
end

render = function()
	if not base.is_valid(state) then return end

	-- status is sync — fast and needed for badge count
	local staged, unstaged = parse_status()
	local seen = {}
	for _, f in ipairs(staged)   do seen[f.path] = true end
	for _, f in ipairs(unstaged) do seen[f.path] = true end
	local total = 0
	for _ in pairs(seen) do total = total + 1 end
	_count_cache = total

	-- async: commits + branches
	local async_data = {}
	local pending    = 2

	local function finish()
		pending = pending - 1
		if pending > 0 then return end
		if not base.is_valid(state) then return end

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
					local ficon, icon_hl = base.file_icon(f.path)
					table.insert(lines,   "  " .. ficon .. " " .. format_path(f.path))
					table.insert(entries, { type = "file", path = f.path, staged = is_staged, icon_hl = icon_hl })
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

		-- commits
		if #async_data.commits > 0 then
			table.insert(lines, ""); table.insert(entries, { type = "empty" })
			local cicon = fold_state.commits and "▸" or "▾"
			table.insert(lines,   cicon .. " Recent commits")
			table.insert(entries, { type = "header", section = "commits" })
			if not fold_state.commits then
				for _, raw in ipairs(async_data.commits) do
					local hash, msg = raw:match("^(%S+)%s+(.+)$")
					if hash then
						table.insert(lines,   "  " .. hash .. " " .. msg)
						table.insert(entries, { type = "commit", hash = hash })
					end
				end
			end
		end

		-- branches
		if #async_data.branches > 0 then
			local LIMIT  = 8
			local bicon  = fold_state.branches and "▸" or "▾"
			local count  = #async_data.branches
			local blabel = count >= LIMIT
				and ("Recent branches (top " .. LIMIT .. ")")
				or  ("Branches (" .. count .. ")")
			table.insert(lines, ""); table.insert(entries, { type = "empty" })
			table.insert(lines,   bicon .. " " .. blabel)
			table.insert(entries, { type = "header", section = "branches" })
			if not fold_state.branches then
				for _, b in ipairs(async_data.branches) do
					local marker = b.is_current and "* " or "  "
					table.insert(lines,   "  " .. marker .. b.name)
					table.insert(entries, { type = "branch", name = b.name, is_current = b.is_current })
				end
			end
		end

		state.entries = entries
		base.set_lines(state, lines)
		apply_highlights(entries)
		require("user.core.sidebar").set_tabbar(state.sidebar_win)
	end

	git_async_lines({ "log", "-5", "--format=%h %s" }, function(lines)
		async_data.commits = lines
		finish()
	end)

	git_async_lines(
		{ "branch", "--sort=-committerdate", "--format=%(HEAD) %(refname:short)" },
		function(lines)
			local LIMIT    = 8
			local branches = {}
			for _, l in ipairs(lines) do
				local head, name = l:match("^([* ]) (.+)$")
				if name and #branches < LIMIT then
					table.insert(branches, { name = name, is_current = head == "*" })
				end
			end
			async_data.branches = branches
			finish()
		end
	)
end

local function refresh()
	_count_cache = nil
	render()
end

-- ── Keymaps ──

local function setup_keymaps()
	local opts = { buffer = state.sidebar_buf, nowait = true }

	vim.keymap.set("n", "<CR>", function()
		local entry = base.cursor_entry(state)
		local ok, neogit = pcall(require, "neogit")
		if not ok then return end
		neogit.open()
		if entry and entry.type == "file" then
			local fname = vim.fn.fnamemodify(entry.path, ":t")
			vim.defer_fn(function()
				if vim.fn.search(vim.fn.escape(fname, "/\\."), "w") > 0 then
					local key = vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
					vim.api.nvim_feedkeys(key, "t", false)
				end
			end, 100)
		end
	end, opts)

	vim.keymap.set("n", "o", function()
		local entry = base.cursor_entry(state)
		if not entry or entry.type ~= "file" then return end
		local win = base.find_target_win(state)
		if not win then return end
		local abs = vim.fn.getcwd() .. "/" .. entry.path
		vim.api.nvim_set_current_win(win)
		vim.cmd("edit " .. vim.fn.fnameescape(abs))
	end, opts)

	vim.keymap.set("n", "z", function()
		local entry = base.cursor_entry(state)
		if not entry or entry.type ~= "header" or not entry.section then return end
		fold_state[entry.section] = not fold_state[entry.section]
		render()
	end, opts)

	vim.keymap.set("n", "r", function() refresh() end, opts)

	base.add_common_keymaps(state, M.close)
end

-- ── Public API ──

function M.open()
	base.open_win(state, {
		filetype   = "GitSidebar",
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
		icon      = "󰊢",
		open      = M.open,
		close     = M.close,
		is_open   = function() return base.is_valid(state) end,
		get_win   = function() return state.sidebar_win end,
		get_count = M.get_count,
	})
end)

return M

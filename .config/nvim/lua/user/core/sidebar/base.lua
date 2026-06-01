local M = {}

local WIDTH  = 55
local WIN_HL = "Normal:NormalFloat,WinSeparator:SymbolSidebarBorder"


function M.is_valid(state)
	return state.sidebar_buf
		and vim.api.nvim_buf_is_valid(state.sidebar_buf)
		and state.sidebar_win
		and vim.api.nvim_win_is_valid(state.sidebar_win)
end

function M.find_target_win(state)
	if state.source_win and vim.api.nvim_win_is_valid(state.source_win) then
		return state.source_win
	end
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if win ~= state.sidebar_win
			and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "" then
			return win
		end
	end
end

-- opts: { filetype, statusline?, cursorline?, winhighlight? }
function M.open_win(state, opts)
	state.source_win = vim.api.nvim_get_current_win()
	if vim.bo[vim.api.nvim_win_get_buf(state.source_win)].buftype ~= "" then
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "" then
				state.source_win = win; break
			end
		end
	end

	state.sidebar_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[state.sidebar_buf].buftype    = "nofile"
	vim.bo[state.sidebar_buf].bufhidden  = "wipe"
	vim.bo[state.sidebar_buf].filetype   = opts.filetype
	vim.bo[state.sidebar_buf].modifiable = false
	vim.bo[state.sidebar_buf].undolevels = -1

	vim.cmd("topleft vsplit")
	state.sidebar_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.sidebar_win, state.sidebar_buf)
	vim.api.nvim_win_set_width(state.sidebar_win, WIDTH)

	vim.wo[state.sidebar_win].number         = true
	vim.wo[state.sidebar_win].relativenumber = true
	vim.wo[state.sidebar_win].signcolumn     = "no"
	vim.wo[state.sidebar_win].wrap           = false
	vim.wo[state.sidebar_win].winfixwidth    = true
	vim.wo[state.sidebar_win].cursorline     = opts.cursorline ~= false
	vim.wo[state.sidebar_win].winhighlight   = opts.winhighlight or WIN_HL

	if opts.statusline then
		vim.wo[state.sidebar_win].statusline = opts.statusline
	end
end

function M.set_lines(state, lines)
	if not M.is_valid(state) then return end
	vim.bo[state.sidebar_buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.sidebar_buf, 0, -1, false, lines)
	vim.bo[state.sidebar_buf].modifiable = false
end

function M.close(state)
	local win = state.sidebar_win
	if not (win and vim.api.nvim_win_is_valid(win)) then return end

	state.sidebar_buf = nil
	state.sidebar_win = nil
	vim.api.nvim_clear_autocmds({ group = state.augroup })
	vim.api.nvim_win_close(win, true)
end

-- extra() is called after base state cleanup inside the WinClosed callback
function M.on_win_closed(state, extra)
	vim.api.nvim_create_autocmd("WinClosed", {
		group    = state.augroup,
		pattern  = tostring(state.sidebar_win),
		once     = true,
		callback = function()
			state.sidebar_buf = nil
			state.sidebar_win = nil
			vim.api.nvim_clear_autocmds({ group = state.augroup })
			if extra then extra() end
		end,
	})
end

-- ── per-project JSON persistence ────────────────────────────────────────────
-- namespace: a short directory name, e.g. "marks_sidebar", "search_sidebar"
-- cwd: optional override; defaults to vim.fn.getcwd()

function M.project_file(namespace, cwd)
	local dir = vim.fn.stdpath("data") .. "/" .. namespace
	vim.fn.mkdir(dir, "p")
	local key = (cwd or vim.fn.getcwd()):gsub("/", "%%")
	return dir .. "/" .. key .. ".json"
end

function M.save_project_data(namespace, data, cwd)
	local ok, encoded = pcall(vim.fn.json_encode, data)
	if not ok then return end
	local f = io.open(M.project_file(namespace, cwd), "w")
	if f then f:write(encoded); f:close() end
end

function M.load_project_data(namespace, cwd)
	local f = io.open(M.project_file(namespace, cwd), "r")
	if not f then return nil end
	local raw = f:read("*a"); f:close()
	local ok, decoded = pcall(vim.fn.json_decode, raw)
	return (ok and type(decoded) == "table") and decoded or nil
end

-- q / > / <lt> keymaps shared by every panel
function M.add_common_keymaps(state, close_fn)
	local opts = { buffer = state.sidebar_buf, nowait = true }
	vim.keymap.set("n", "q",    close_fn, opts)
	vim.keymap.set("n", ">",    function() require("user.core.sidebar").resize(4)  end, opts)
	vim.keymap.set("n", "<lt>", function() require("user.core.sidebar").resize(-4) end, opts)
end

-- Factory: returns a new per-panel state table with standard base fields.
function M.new_state(augroup_name)
	return {
		sidebar_buf = nil,
		sidebar_win = nil,
		source_win  = nil,
		entries     = {},
		augroup     = vim.api.nvim_create_augroup(augroup_name, { clear = true }),
	}
end

-- Returns a close function for panels whose only cleanup is base.close + entries reset.
function M.make_close(state)
	return function()
		M.close(state)
		state.entries = {}
	end
end

-- Returns the entry and 1-based line at the sidebar cursor, or nil, nil.
function M.cursor_entry(state)
	if not M.is_valid(state) then return nil, nil end
	local line = vim.api.nvim_win_get_cursor(state.sidebar_win)[1]
	return state.entries[line], line
end

-- Define highlight groups and re-apply them on every ColorScheme change.
-- defs: list of { "HlGroupName", { attrs } }
function M.setup_hl(defs)
	local function apply()
		for _, d in ipairs(defs) do
			vim.api.nvim_set_hl(0, d[1], d[2])
		end
	end
	vim.api.nvim_create_autocmd("ColorScheme", { callback = apply })
	apply()
end

return M

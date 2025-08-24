local cmp = {} -- statusline components
local hi_pattern = "%%#%s#%s%%*"

function _G._statusline_component(name)
	return cmp[name]()
end

function cmp.position()
	return hi_pattern:format("Search", "  %3l:%-2c ")
end

-- Git branch
local git_branch_cache = {}
function cmp.git_branch()
	local devicons = require("nvim-web-devicons")
	local cwd = vim.fn.getcwd()

	local now = vim.fn.localtime()
	if git_branch_cache[cwd] and (now - git_branch_cache[cwd].time) < 5 then
		return git_branch_cache[cwd].result
	end

	local handle = io.popen("git -C " .. vim.fn.shellescape(cwd) .. " branch --show-current 2>/dev/null")
	local branch = handle and handle:read("*l") or ""
	if handle then
		handle:close()
	end

	local result = ""
	if branch and branch ~= "" then
		result = hi_pattern:format("DiffAdd", "   " .. branch .. "  ")
	end

	git_branch_cache[cwd] = { result = result, time = now }
	return result
end

-- LSP clients
function cmp.lsp_clients()
	local buf_clients = vim.lsp.get_active_clients({ bufnr = 0 })
	if #buf_clients == 0 then
		return ""
	end

	local client_names = {}
	for _, client in ipairs(buf_clients) do
		table.insert(client_names, client.name)
	end

	local lsp_info = table.concat(client_names, ", ")
	return hi_pattern:format("Function", "   " .. lsp_info .. "  ")
end

-- Filename với icon
function cmp.filename()
	local devicons = require("nvim-web-devicons")
	local filename = vim.fn.expand("%:t")

	if filename == "" then
		return hi_pattern:format("Comment", "  [No Name] ")
	end

	local icon, icon_hl = devicons.get_icon(filename, vim.fn.expand("%:e"), { default = true })

	if icon then
		return " " .. hi_pattern:format(icon_hl or "Normal", icon) .. " " .. filename
	else
		return "  " .. filename
	end
end

-- Filetype với icon
function cmp.filetype()
	local devicons = require("nvim-web-devicons")
	local ft = vim.bo.filetype

	if ft == "" then
		return ""
	end

	local icon = devicons.get_icon_by_filetype(ft, { default = true })

	if icon then
		return " " .. icon .. " " .. ft .. " "
	else
		return " " .. ft .. " "
	end
end

-- Percentage với icon
function cmp.percentage()
	return "  %2p%%  "
end

local statusline = {
	'%{%v:lua._statusline_component("git_branch")%}',
	'%{%v:lua._statusline_component("filename")%}',
	-- "%r",
	"%=",
	'%{%v:lua._statusline_component("lsp_clients")%}',
	'%{%v:lua._statusline_component("filetype")%}',
	'%{%v:lua._statusline_component("percentage")%}',
	'%{%v:lua._statusline_component("position")%}',
}

return statusline

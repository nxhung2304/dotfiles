local components = {}
local hi_pattern = "%%#%s#%s%%*"

function components.xcode_device()
  if not vim.g.xcodebuild_platform then
    return ""
  end

	if vim.g.xcodebuild_platform == "macOS" then
		return " macOS"
	end

	local deviceIcon = ""
	if vim.g.xcodebuild_platform:match("watch") then
		deviceIcon = "􀟤"
	elseif vim.g.xcodebuild_platform:match("tv") then
		deviceIcon = "􀡴 "
	elseif vim.g.xcodebuild_platform:match("vision") then
		deviceIcon = "􁎖 "
	end

	if vim.g.xcodebuild_os then
		return deviceIcon .. " " .. vim.g.xcodebuild_device_name .. " (" .. vim.g.xcodebuild_os .. ")"
	end

	return deviceIcon .. " " .. vim.g.xcodebuild_device_name
end

function _G._statusline_component(name)
	return components[name]()
end

function components.position()
	return hi_pattern:format("Search", "  %3l:%-2c ")
end

-- Git branch
local git_branch_cache = {}
function components.git_branch()
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
		result = hi_pattern:format("DiffAdd", " 󰘬  " .. branch .. "  ") -- 󰘬
	end

	git_branch_cache[cwd] = { result = result, time = now }
	return result
end

-- LSP clients
function components.lsp_clients()
	local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
	if #buf_clients == 0 then
		return ""
	end

	local client_names = {}
	for _, client in ipairs(buf_clients) do
		table.insert(client_names, client.name)
	end

	local lsp_info = table.concat(client_names, ", ")
	return hi_pattern:format("Function", "   [" .. lsp_info .. "]  ")
end

-- Filename với icon
function components.filename()
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

function components.filetype()
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

function components.indent_info()
	local expandtab = vim.bo.expandtab
	local shiftwidth = vim.bo.shiftwidth
	local tabstop = vim.bo.tabstop

	local indent_info
	if expandtab then
		indent_info = "space: " .. shiftwidth
	else
		indent_info = "tab:" .. tabstop
	end

	return hi_pattern:format("Special", "  " .. indent_info)
end

local statusline = {
	'%{%v:lua._statusline_component("git_branch")%}',
	"%r",
	"%=",
	'%{%v:lua._statusline_component("xcode_device")%}',
	'%{%v:lua._statusline_component("indent_info")%}',
	'%{%v:lua._statusline_component("lsp_clients")%}',
	'%{%v:lua._statusline_component("filetype")%}',
	'%{%v:lua._statusline_component("position")%}',
}

return statusline

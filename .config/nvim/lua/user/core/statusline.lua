local components = {}
local hi_pattern = "%%#%s#%s%%*"

function _G._statusline_component(name)
	return components[name]()
end

local click_actions = {
	git_branch = function()
		vim.system({ vim.fn.expand("~/dotfiles/scripts/herdr/open-git-page"), "current" })
	end,
	diagnostics = function()
		require("user.core.diagnostics_outline").toggle()
	end,
	lsp = function()
		vim.cmd("checkhealth vim.lsp")
	end,
	flutter_device = function()
		vim.cmd("FlutterDevices")
	end,
}
local click_ids = { "git_branch", "diagnostics", "lsp", "flutter_device" }

function _G._statusline_click(id, _, button)
	if button ~= "l" then
		return
	end
	click_actions[click_ids[id]]()
end

local function clickable(action_name, text)
	local id = vim.fn.index(click_ids, action_name) + 1
	return "%" .. id .. "@v:lua._statusline_click@" .. text .. "%X"
end

function components.position()
	local current_line = vim.fn.line(".")
	local total_lines = vim.fn.line("$")
	local progress = total_lines > 1 and (current_line - 1) / (total_lines - 1) or 0
	return string.format(" %3d%%%% ", math.floor(progress * 100 + 0.5))
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
		result = clickable("git_branch", hi_pattern:format("DiagnosticOk", " 󰘬  " .. branch .. "  ")) -- 󰘬
	end

	git_branch_cache[cwd] = { result = result, time = now }
	return result
end
function components.diagnostic_status()
	local diagnostics = vim.diagnostic.get(0)

	if not diagnostics or vim.tbl_isempty(diagnostics) then
		return ""
	end

	local counts = {
		errors = 0,
		warnings = 0,
		info = 0,
		hints = 0,
	}

	for _, diagnostic in ipairs(diagnostics) do
		if diagnostic.severity == vim.diagnostic.severity.ERROR then
			counts.errors = counts.errors + 1
		elseif diagnostic.severity == vim.diagnostic.severity.WARN then
			counts.warnings = counts.warnings + 1
		elseif diagnostic.severity == vim.diagnostic.severity.INFO then
			counts.info = counts.info + 1
		elseif diagnostic.severity == vim.diagnostic.severity.HINT then
			counts.hints = counts.hints + 1
		end
	end

	local parts = {}

	if counts.errors > 0 then
		table.insert(parts, "%#DiagnosticError# " .. counts.errors)
	end
	if counts.warnings > 0 then
		table.insert(parts, "%#DiagnosticWarn# " .. counts.warnings)
	end
	if counts.info > 0 then
		table.insert(parts, "%#DiagnosticInfo# " .. counts.info)
	end
	if counts.hints > 0 then
		table.insert(parts, "%#DiagnosticHint#󰌵 " .. counts.hints)
	end

	if #parts == 0 then
		return ""
	end

	return clickable("diagnostics", "  " .. table.concat(parts, " ") .. " %*")
end

-- LSP clients
function components.lsp_clients()
	local names = {}
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
		table.insert(names, client.name)
	end
	if #names == 0 then
		return ""
	end
	return clickable("lsp", hi_pattern:format("Comment", " " .. table.concat(names, ",") .. " "))
end

-- Filename với icon
function components.filename()
	local filename = vim.fn.expand("%:t")

	if filename == "" then
		return hi_pattern:format("Comment", "  [No Name] ")
	end

	local icon, icon_hl = require("nvim-web-devicons").get_icon(filename, nil, { default = true })

	if icon then
		return " " .. hi_pattern:format(icon_hl or "Normal", icon) .. " " .. filename
	else
		return "  " .. filename
	end
end

function components.filetype()
	local ft = vim.bo.filetype

	if ft == "" then
		return ""
	end

	local icon = require("nvim-web-devicons").get_icon_by_filetype(ft, { default = true })

	if icon then
		return " " .. icon .. " "
	else
		return " " .. ft .. " "
	end
end

vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
	callback = function()
		vim.cmd("redrawstatus")
	end,
})

function components.macro()
	local register = vim.fn.reg_recording()
	if register == "" then
		return ""
	end
	return hi_pattern:format("WarningMsg", "  Recording @" .. register .. "  ")
end

-- Icon per device platform: phone (iOS/Android), desktop (macOS/Windows/Linux),
-- browser (Chrome/web).
local function flutter_device_icon(platform)
  platform = (platform or ""):lower()
  if platform:find("ios", 1, true) or platform:find("android", 1, true) then
    return "\u{f10b} " -- nf-fa-mobile
  elseif platform:find("macos", 1, true) or platform:find("windows", 1, true) or platform:find("linux", 1, true) then
    return "\u{f108} " -- nf-fa-desktop
  elseif platform:find("chrome", 1, true) or platform:find("web", 1, true) then
    return "\u{f268} " -- nf-fa-chrome
  end
  return " "
end

function components.flutter_device()
  local decorations = vim.g.flutter_tools_decorations
  -- flutter-tools stores the running device as a table ({name, id, platform, ...}).
  -- Fall back to the auto-picked default device before any run session starts.
  local device = (decorations and decorations.device) or vim.g.flutter_preferred_device
  if type(device) ~= "table" or not device.name or device.name == "" then
    return ""
  end
  -- Strip the trailing "(mobile)"/"(desktop)"/"(web)" annotation flutter appends to the name
  local name = device.name:gsub(" %([^%(%)]-%)%s*$", "")
  return clickable("flutter_device", "  " .. flutter_device_icon(device.platform) .. name .. " ")
end

vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
	callback = function()
		vim.schedule(function()
			vim.cmd("redrawstatus")
		end)
	end,
})

function components.indent()
	if vim.bo.expandtab then
		return " Spaces:" .. vim.fn.shiftwidth() .. " "
	end
	return " Tab:" .. vim.bo.tabstop .. " "
end

local statusline = {
	'%{%v:lua._statusline_component("git_branch")%}',
	'%{%v:lua._statusline_component("diagnostic_status")%}',
	'%{%v:lua._statusline_component("macro")%}',
	"%r",
	"%=",
	'%{%v:lua._statusline_component("lsp_clients")%}',
	'%{%v:lua._statusline_component("flutter_device")%}',
	'%{%v:lua._statusline_component("position")%}',
}

return statusline

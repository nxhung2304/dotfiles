local M = {}

local GENERATED_FILE_SUFFIXES = { ".g.dart", ".freezed.dart" }
local ENVIRONMENT_CALL_PATTERN = "%a+%.fromEnvironment%(%s*['\"]([%w_]+)['\"]([^)]*)%)"
local PROJECT_ENTRY_PATTERN = "^%s*{.-name%s*=.*}%s*,?%s*$"
local DEFAULT_ENTRY_NAME = "Default"
local PROJECT_CONFIG_FILE_NAME = ".nvim.lua"

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "Flutter" })
end

local function is_generated_file(file_path)
	for _, suffix in ipairs(GENERATED_FILE_SUFFIXES) do
		if vim.endswith(file_path, suffix) then
			return true
		end
	end
	return false
end

local function parse_default_value(call_arguments)
	local quoted_value = call_arguments:match("defaultValue:%s*['\"]([^'\"]*)['\"]")
	return quoted_value or call_arguments:match("defaultValue:%s*([%w_.%-]+)") or ""
end

local function scan_dart_defines(project_root)
	local defines = {}
	for _, file_path in ipairs(vim.fn.glob(project_root .. "/lib/**/*.dart", false, true)) do
		if not is_generated_file(file_path) then
			local source = table.concat(vim.fn.readfile(file_path), "\n")
			for key, call_arguments in source:gmatch(ENVIRONMENT_CALL_PATTERN) do
				defines[key] = defines[key] or parse_default_value(call_arguments)
			end
		end
	end
	return defines
end

local function sorted_keys(defines)
	local keys = vim.tbl_keys(defines)
	table.sort(keys)
	return keys
end

local function format_define(key, value)
	return string.format("%s = %q", key, value)
end

local function find_missing_keys(existing_defines_text, defines)
	local missing_keys = {}
	for _, key in ipairs(sorted_keys(defines)) do
		if not (" " .. existing_defines_text):find("[%s,{]" .. key .. "%s*=") then
			table.insert(missing_keys, key)
		end
	end
	return missing_keys
end

local function format_defines(keys, defines)
	local formatted = {}
	for _, key in ipairs(keys) do
		table.insert(formatted, format_define(key, defines[key]))
	end
	return table.concat(formatted, ", ")
end

local function add_missing_defines_to_entry(entry_line, defines)
	local existing_defines_text = entry_line:match("dart_define%s*=%s*{([^}]*)}")
	local missing_keys = find_missing_keys(existing_defines_text or "", defines)
	if #missing_keys == 0 then
		return entry_line, {}
	end

	local additions = format_defines(missing_keys, defines)
	if existing_defines_text then
		local separator = existing_defines_text:match("%S") and ", " or " "
		local updated_line = entry_line:gsub("(dart_define%s*=%s*{[^}]*)}", function(head)
			return head:gsub("%s*$", "") .. separator .. additions .. " }"
		end, 1)
		return updated_line, missing_keys
	end

	local updated_line = entry_line:gsub("^(%s*{.*)}(%s*,?%s*)$", function(head, tail)
		return head:gsub("%s*$", "") .. ", dart_define = { " .. additions .. " } }" .. tail
	end)
	return updated_line, missing_keys
end

local function merge_into_config_lines(config_lines, defines)
	local merged_lines = {}
	local added_keys = {}
	local entry_count = 0
	for _, line in ipairs(config_lines) do
		if line:match(PROJECT_ENTRY_PATTERN) then
			entry_count = entry_count + 1
			local updated_line, missing_keys = add_missing_defines_to_entry(line, defines)
			vim.list_extend(added_keys, missing_keys)
			table.insert(merged_lines, updated_line)
		else
			table.insert(merged_lines, line)
		end
	end

	local declared_entry_count = select(2, table.concat(config_lines, "\n"):gsub("name%s*=", ""))
	return merged_lines, added_keys, entry_count ~= declared_entry_count
end

local function build_new_config_lines(defines)
	local entry = string.format(
		'\t{ name = "%s", dart_define = { %s } },',
		DEFAULT_ENTRY_NAME,
		format_defines(sorted_keys(defines), defines)
	)
	return { 'require("flutter-tools").setup_project({', entry, "})" }
end

local function ensure_config_is_gitignored(project_root)
	if not vim.uv.fs_stat(project_root .. "/.git") then
		return
	end

	local gitignore_path = project_root .. "/.gitignore"
	local ignored_lines = vim.uv.fs_stat(gitignore_path) and vim.fn.readfile(gitignore_path) or {}
	for _, line in ipairs(ignored_lines) do
		local pattern = vim.trim(line)
		if pattern == PROJECT_CONFIG_FILE_NAME or pattern == "/" .. PROJECT_CONFIG_FILE_NAME then
			return
		end
	end

	table.insert(ignored_lines, PROJECT_CONFIG_FILE_NAME)
	vim.fn.writefile(ignored_lines, gitignore_path)
	notify("Added " .. PROJECT_CONFIG_FILE_NAME .. " to .gitignore")
end

local function save_and_apply_config(config_path, config_lines)
	ensure_config_is_gitignored(vim.fs.dirname(config_path))
	vim.fn.writefile(config_lines, config_path)
	vim.secure.trust({ action = "allow", path = config_path })
	dofile(config_path)
end

function M.setup_config_autotrust()
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup("FlutterProjectConfigTrust", { clear = true }),
		pattern = "*/" .. PROJECT_CONFIG_FILE_NAME,
		callback = function(event)
			local config_path = vim.api.nvim_buf_get_name(event.buf)
			if not vim.fs.root(config_path, "pubspec.yaml") then
				return
			end

			vim.secure.trust({ action = "allow", bufnr = event.buf })
			dofile(config_path)
			notify("Reloaded " .. PROJECT_CONFIG_FILE_NAME)
		end,
	})
end

function M.update_project_config()
	local project_root = vim.fs.root(vim.fn.getcwd(), "pubspec.yaml")
	if not project_root then
		notify("No pubspec.yaml found", vim.log.levels.WARN)
		return
	end

	local defines = scan_dart_defines(project_root)
	if next(defines) == nil then
		notify("No dart-define key found in lib/")
		return
	end

	local config_path = project_root .. "/" .. PROJECT_CONFIG_FILE_NAME
	if not vim.uv.fs_stat(config_path) then
		save_and_apply_config(config_path, build_new_config_lines(defines))
		notify("Created .nvim.lua with: " .. table.concat(sorted_keys(defines), ", "))
		return
	end

	local merged_lines, added_keys, has_unmerged_entries =
		merge_into_config_lines(vim.fn.readfile(config_path), defines)
	if has_unmerged_entries then
		notify(
			".nvim.lua has entries that are not on a single line; add by hand: "
				.. format_defines(sorted_keys(defines), defines),
			vim.log.levels.WARN
		)
	end
	if #added_keys == 0 then
		if not has_unmerged_entries then
			notify("dart_define in .nvim.lua is already up to date")
		end
		return
	end

	table.sort(added_keys)
	save_and_apply_config(config_path, merged_lines)
	notify("Added to .nvim.lua: " .. table.concat(vim.fn.uniq(added_keys), ", "))
end

return M

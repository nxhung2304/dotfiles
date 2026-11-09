local M = {}

local TEMPLATE_DIR = vim.fn.stdpath("config") .. "/templates/flutter"
local PROJECT_TEMPLATE_DIR_NAME = ".flutter-templates"
local TEMPLATE_EXTENSION = ".dart.tpl"
local FEATURES_DIR = "lib/features"
local RIVERPOD_ANNOTATION = "riverpod_annotation"
local FLUTTER_RIVERPOD = "flutter_riverpod"
local JSON_ANNOTATION = "json_annotation"
local CONTROLLER_DIR_CANDIDATES = { "controller", "controllers" }
local NOTIFY_TITLE = "Flutter New"
local NEW_FEATURE_LABEL = "<new feature>"
local SNAKE_CASE_PATTERN = "^[a-z][a-z0-9_]*$"

local MESSAGE_NO_SCAFFOLD_KINDS = "No feature template fits this project's dependencies"
local PROMPT_INCLUDE_PREFIX = "Also create"
local CHOICE_NO = "No"
local CHOICE_YES = "Yes"
local PROMPT_KIND = "Create"
local PROMPT_FEATURE = "Feature"
local PROMPT_NEW_FEATURE = "New feature name (snake_case)"
local PROMPT_NAME = "Name (snake_case, e.g. course)"

local KINDS = {
	{
		label = "Remote data source",
		in_feature_scaffold = true,
		requires = { RIVERPOD_ANNOTATION },
		files = {
			{ template = "remote_data_source", path = "data/data_sources/{{snake}}_remote_data_source.dart" },
		},
	},
	{
		label = "Local data source",
		optional_in_feature_scaffold = true,
		requires = { RIVERPOD_ANNOTATION },
		files = {
			{ template = "local_data_source", path = "data/data_sources/{{snake}}_local_data_source.dart" },
		},
	},
	{
		label = "Repository (interface + impl)",
		in_feature_scaffold = true,
		requires = { RIVERPOD_ANNOTATION },
		files = {
			{ template = "repository", path = "domain/repositories/{{snake}}_repository.dart" },
			{ template = "repository_impl", path = "data/repositories/{{snake}}_repository_impl.dart" },
		},
	},
	{
		label = "Use case",
		optional_in_feature_scaffold = true,
		requires = { RIVERPOD_ANNOTATION },
		files = {
			{ template = "use_case", path = "domain/usecases/{{snake}}_use_case.dart" },
		},
	},
	{
		label = "Controller",
		in_feature_scaffold = true,
		requires = { RIVERPOD_ANNOTATION },
		files = {
			{ template = "controller", path = "presentation/{{controller_dir}}/{{snake}}_controller.dart" },
		},
	},
	{
		label = "Model (json_serializable)",
		requires = { JSON_ANNOTATION },
		files = {
			{ template = "model", path = "data/models/{{snake}}_model.dart" },
		},
	},
	{
		label = "Entity",
		requires = {},
		files = {
			{ template = "entity", path = "domain/entities/{{snake}}.dart" },
		},
	},
	{
		label = "Screen (ConsumerWidget)",
		in_feature_scaffold = true,
		requires = { FLUTTER_RIVERPOD },
		files = {
			{ template = "screen", path = "presentation/screens/{{snake}}_screen.dart" },
		},
	},
	{
		label = "Widget (StatelessWidget)",
		requires = {},
		files = {
			{ template = "widget", path = "presentation/widgets/{{snake}}.dart" },
		},
	},
}

local function notify_error(message)
	vim.notify(message, vim.log.levels.ERROR, { title = NOTIFY_TITLE })
end

local function pascal_case(snake_name)
	local parts = {}
	for part in snake_name:gmatch("[^_]+") do
		table.insert(parts, part:sub(1, 1):upper() .. part:sub(2))
	end
	return table.concat(parts)
end

local function camel_case(snake_name)
	local pascal_name = pascal_case(snake_name)
	return pascal_name:sub(1, 1):lower() .. pascal_name:sub(2)
end

local function render(text, variables)
	return (text:gsub("{{([%w_]+)}}", function(key)
		return variables[key]
	end))
end

local function read_pubspec(project_root)
	local pubspec_path = project_root .. "/pubspec.yaml"
	if vim.fn.filereadable(pubspec_path) == 0 then
		return nil
	end
	return vim.fn.readfile(pubspec_path)
end

local function parse_package_name(pubspec_lines)
	for _, line in ipairs(pubspec_lines) do
		local package_name = line:match("^name:%s*(%S+)")
		if package_name then
			return package_name
		end
	end
	return nil
end

local function has_dependency(pubspec_lines, dependency_name)
	for _, line in ipairs(pubspec_lines) do
		if line:match("^%s+" .. dependency_name .. ":") then
			return true
		end
	end
	return false
end

local function list_features(features_root)
	local features = {}
	for _, entry in ipairs(vim.fn.readdir(features_root)) do
		if vim.fn.isdirectory(features_root .. "/" .. entry) == 1 then
			table.insert(features, entry)
		end
	end
	return features
end

local function count_controller_dirs(features_root, features)
	local counts = {}
	for _, feature in ipairs(features) do
		for _, candidate in ipairs(CONTROLLER_DIR_CANDIDATES) do
			if vim.fn.isdirectory(("%s/%s/presentation/%s"):format(features_root, feature, candidate)) == 1 then
				counts[candidate] = (counts[candidate] or 0) + 1
			end
		end
	end
	return counts
end

local function detect_controller_dir(features_root, feature)
	local own_counts = count_controller_dirs(features_root, { feature })
	local all_counts = count_controller_dirs(features_root, list_features(features_root))
	local best_dir = CONTROLLER_DIR_CANDIDATES[1]
	local best_score = -1
	for _, candidate in ipairs(CONTROLLER_DIR_CANDIDATES) do
		local score = (own_counts[candidate] or 0) * 1000 + (all_counts[candidate] or 0)
		if score > best_score then
			best_dir = candidate
			best_score = score
		end
	end
	return best_dir
end

local function load_template(project_root, template_name)
	local file_name = template_name .. TEMPLATE_EXTENSION
	local project_template = ("%s/%s/%s"):format(project_root, PROJECT_TEMPLATE_DIR_NAME, file_name)
	local template_path = vim.fn.filereadable(project_template) == 1 and project_template
		or TEMPLATE_DIR .. "/" .. file_name
	if vim.fn.filereadable(template_path) == 0 then
		return nil
	end
	return table.concat(vim.fn.readfile(template_path), "\n") .. "\n"
end

local function write_new_file(target_path, content)
	if vim.fn.filereadable(target_path) == 1 then
		notify_error("Already exists: " .. target_path)
		return false
	end
	vim.fn.mkdir(vim.fn.fnamemodify(target_path, ":h"), "p")
	local write_result = vim.fn.writefile(vim.split(content, "\n", { trimempty = false }), target_path)
	if write_result ~= 0 then
		notify_error("Cannot write: " .. target_path)
		return false
	end
	return true
end

local function create_files(project, kinds, feature, snake_name)
	local feature_root = ("%s/%s/%s"):format(project.root, FEATURES_DIR, feature)
	local variables = {
		package = project.package_name,
		feature = feature,
		snake = snake_name,
		Pascal = pascal_case(snake_name),
		camel = camel_case(snake_name),
		controller_dir = detect_controller_dir(project.root .. "/" .. FEATURES_DIR, feature),
	}

	local contents = {}
	for _, kind in ipairs(kinds) do
		for _, file in ipairs(kind.files) do
			local template = load_template(project.root, file.template)
			if not template then
				notify_error("Missing template: " .. file.template)
				return
			end
			table.insert(contents, {
				path = feature_root .. "/" .. render(file.path, variables),
				text = render(template, variables),
			})
		end
	end

	local created_paths = {}
	for _, content in ipairs(contents) do
		if write_new_file(content.path, content.text) then
			table.insert(created_paths, content.path)
		end
	end
	if #created_paths == 0 then
		return
	end

	vim.cmd("edit " .. vim.fn.fnameescape(created_paths[1]))
	vim.notify(
		"Created:\n" .. table.concat(vim.tbl_map(function(path)
			return vim.fn.fnamemodify(path, ":.")
		end, created_paths), "\n"),
		vim.log.levels.INFO,
		{ title = NOTIFY_TITLE }
	)
end

local function ask_name(default_name, on_name)
	vim.ui.input({ prompt = PROMPT_NAME .. ": ", default = default_name }, function(input)
		if not input or input == "" then
			return
		end
		if not input:match(SNAKE_CASE_PATTERN) then
			notify_error("Name must be snake_case: " .. input)
			return
		end
		on_name(input)
	end)
end

local function ask_feature(features, on_feature)
	local choices = vim.list_extend(vim.deepcopy(features), { NEW_FEATURE_LABEL })
	vim.ui.select(choices, { prompt = PROMPT_FEATURE }, function(choice)
		if not choice then
			return
		end
		if choice ~= NEW_FEATURE_LABEL then
			on_feature(choice)
			return
		end
		vim.ui.input({ prompt = PROMPT_NEW_FEATURE .. ": " }, function(input)
			if not input or not input:match(SNAKE_CASE_PATTERN) then
				return
			end
			on_feature(input)
		end)
	end)
end

local function available_kinds(pubspec_lines)
	return vim.tbl_filter(function(kind)
		for _, dependency_name in ipairs(kind.requires) do
			if not has_dependency(pubspec_lines, dependency_name) then
				return false
			end
		end
		return true
	end, KINDS)
end

local function ask_kind(kinds, on_kind)
	vim.ui.select(kinds, {
		prompt = PROMPT_KIND,
		format_item = function(kind)
			return kind.label
		end,
	}, function(kind)
		if kind then
			on_kind(kind)
		end
	end)
end

local function detect_project()
	local project_root = vim.fs.root(0, "pubspec.yaml")
	if not project_root then
		notify_error("No pubspec.yaml found above the current file")
		return nil
	end

	local pubspec_lines = read_pubspec(project_root)
	local package_name = pubspec_lines and parse_package_name(pubspec_lines)
	if not package_name then
		notify_error("Cannot read package name from pubspec.yaml")
		return nil
	end

	local features_root = project_root .. "/" .. FEATURES_DIR
	if vim.fn.isdirectory(features_root) == 0 then
		notify_error("Missing directory: " .. FEATURES_DIR)
		return nil
	end

	return {
		root = project_root,
		package_name = package_name,
		features_root = features_root,
		pubspec_lines = pubspec_lines,
	}
end

function M.prompt_new_file()
	local project = detect_project()
	if not project then
		return
	end

	ask_kind(available_kinds(project.pubspec_lines), function(kind)
		ask_feature(list_features(project.features_root), function(feature)
			ask_name(nil, function(snake_name)
				create_files(project, { kind }, feature, snake_name)
			end)
		end)
	end)
end

local function ask_optional_kinds(optional_kinds, on_chosen)
	local chosen_kinds = {}

	local function ask_next(index)
		if index > #optional_kinds then
			on_chosen(chosen_kinds)
			return
		end
		local kind = optional_kinds[index]
		vim.ui.select({ CHOICE_NO, CHOICE_YES }, { prompt = ("%s %s?"):format(PROMPT_INCLUDE_PREFIX, kind.label) }, function(choice)
			if not choice then
				return
			end
			if choice == CHOICE_YES then
				table.insert(chosen_kinds, kind)
			end
			ask_next(index + 1)
		end)
	end

	ask_next(1)
end

function M.prompt_new_feature()
	local project = detect_project()
	if not project then
		return
	end

	local kinds = available_kinds(project.pubspec_lines)
	local required_kinds = vim.tbl_filter(function(kind)
		return kind.in_feature_scaffold
	end, kinds)
	local optional_kinds = vim.tbl_filter(function(kind)
		return kind.optional_in_feature_scaffold
	end, kinds)
	if #required_kinds + #optional_kinds == 0 then
		notify_error(MESSAGE_NO_SCAFFOLD_KINDS)
		return
	end

	ask_feature(list_features(project.features_root), function(feature)
		ask_name(feature, function(snake_name)
			ask_optional_kinds(optional_kinds, function(chosen_optional_kinds)
				local scaffold_kinds = vim.list_extend(vim.deepcopy(required_kinds), chosen_optional_kinds)
				create_files(project, scaffold_kinds, feature, snake_name)
			end)
		end)
	end)
end

return M

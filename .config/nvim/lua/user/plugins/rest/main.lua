-- rest_templates.lua (main file)
local M = {}

local workspace = require("user.plugins.rest.rest_workspace")
local file_utils = require("user.plugins.rest.rest_file_utils")
local http_templates = require("user.plugins.rest.templates.http_template")

-- Export workspace path
M.rest_workspace = workspace.rest_workspace

function M.create_template(template_name, in_workspace)
	local target_dir = in_workspace and workspace.rest_workspace or vim.fn.getcwd()

	if in_workspace then
		workspace.ensure_workspace()
	end

	local template_content = http_templates.render[template_name]
	if not template_content then
		vim.notify("Template '" .. template_name .. "' not found", vim.log.levels.ERROR)
		return false
	end

	local file_path = vim.fs.joinpath(target_dir, template_name)
	return file_utils.create_file(file_path, template_content)
end

function M.select_template()
	local templates = vim.tbl_keys(http_templates.render)

	vim.ui.select(templates, {
		prompt = "Select REST template:",
		format_item = function(item)
			return item:gsub("%.http$", "")
		end,
	}, function(choice)
		if choice then
			M.create_template(choice)
			vim.cmd("edit " .. choice)
		end
	end)
end

function M.select_template_in_workspace()
	workspace.ensure_workspace()

	local templates = vim.tbl_keys(http_templates.render)

	vim.ui.select(templates, {
		prompt = "Select REST template for workspace:",
		format_item = function(item)
			return item:gsub("%.http$", "")
		end,
	}, function(choice)
		if choice then
			local file_path = M.create_template(choice, true)
			if file_path then
				-- Chuyển đến workspace và mở file
				vim.cmd("cd " .. workspace.rest_workspace)
				vim.cmd("edit " .. file_path)
			end
		end
	end)
end

function M.setup_rest_workspace()
	workspace.ensure_workspace()

	vim.notify("Setting up REST workspace in " .. workspace.rest_workspace, vim.log.levels.INFO)

	-- Create all templates
	local created_count = 0
	for template_name, _ in pairs(http_templates.render) do
		local file_path = vim.fs.joinpath(workspace.rest_workspace, template_name)
		if vim.fn.filereadable(file_path) == 0 then
			if M.create_template(template_name, true) then
				created_count = created_count + 1
			end
		end
	end

	-- Create .env file
	if file_utils.create_env_file(workspace.rest_workspace) then
		created_count = created_count + 1
	end

	vim.notify(string.format("REST workspace setup complete! Created %d files", created_count), vim.log.levels.INFO)

	-- Chuyển đến workspace
	workspace.open_rest_workspace()
end

-- Export workspace functions
M.open_rest_workspace = workspace.open_rest_workspace
M.list_workspace_files = workspace.list_workspace_files
M.is_in_workspace = workspace.is_in_workspace

return M

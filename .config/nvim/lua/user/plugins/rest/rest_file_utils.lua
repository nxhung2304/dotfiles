-- rest_file_utils.lua
local M = {}

function M.create_file(file_path, content)
	-- Check if file exists
	if vim.fn.filereadable(file_path) == 1 then
		local choice = vim.fn.confirm(
			"File " .. vim.fn.fnamemodify(file_path, ":t") .. " already exists. Overwrite?",
			"&Yes\n&No", 2
		)
		if choice ~= 1 then
			return false
		end
	end

	-- Write file
	local file = io.open(file_path, "w")
	if not file then
		vim.notify("Failed to create " .. file_path, vim.log.levels.ERROR)
		return false
	end

	file:write(content)
	file:close()

	vim.notify("Created " .. file_path, vim.log.levels.INFO)
	return file_path
end

function M.create_env_file(target_dir)
	local env_template = require("templates.env_template")
	target_dir = target_dir or vim.fn.getcwd()
	local file_path = vim.fs.joinpath(target_dir, ".env")

	if vim.fn.filereadable(file_path) == 1 then
		vim.notify(".env file already exists", vim.log.levels.WARN)
		return false
	end

	return M.create_file(file_path, env_template.render)
end

return M

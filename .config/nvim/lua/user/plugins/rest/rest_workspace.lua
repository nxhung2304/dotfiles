-- rest_workspace.lua
local M = {}

M.rest_workspace = vim.fs.joinpath(vim.fn.expand("~"), "rest-workspace")

function M.ensure_workspace()
	if vim.fn.isdirectory(M.rest_workspace) == 0 then
		vim.fn.mkdir(M.rest_workspace, "p")
	end
end

function M.open_rest_workspace()
	M.ensure_workspace()

	-- Chuyển đến workspace
	vim.cmd("cd " .. M.rest_workspace)

	-- Mở file explorer
	vim.cmd("NvimTreeOpen")

	-- Tìm file .http đầu tiên hoặc tạo basic.http
	local http_files = vim.fn.glob(M.rest_workspace .. "/*.http", false, true)

	if #http_files > 0 then
		vim.cmd("edit " .. http_files[1])
	else
		-- Tạo basic.http nếu chưa có
		local templates = require("user.plugins.rest.main")
		local file_path = templates.create_template("basic.http", true)
		if file_path then
			vim.cmd("edit " .. file_path)
		end
	end

	vim.notify("Opened REST workspace: " .. M.rest_workspace, vim.log.levels.INFO)
end

function M.list_workspace_files()
	M.ensure_workspace()

	local files = vim.fn.glob(M.rest_workspace .. "/*.http", false, true)

	if #files == 0 then
		vim.notify("No .http files in workspace. Create some first!", vim.log.levels.WARN)
		return
	end

	-- Format file names
	local file_names = {}
	for _, file in ipairs(files) do
		table.insert(file_names, vim.fn.fnamemodify(file, ":t"))
	end

	vim.ui.select(file_names, {
		prompt = "Select REST file:",
	}, function(choice)
		if choice then
			local file_path = vim.fs.joinpath(M.rest_workspace, choice)
			vim.cmd("cd " .. M.rest_workspace)
			vim.cmd("edit " .. file_path)
		end
	end)
end

function M.is_in_workspace()
	local cwd = vim.fn.getcwd()
	return cwd == M.rest_workspace
end

return M

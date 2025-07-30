vim.api.nvim_create_user_command("TeleSmartOpen", function()
	require("telescope").extensions.smart_open.smart_open()
end, { desc = "Open smart-open" })

vim.api.nvim_create_user_command("CopyAbsolutePath", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

vim.api.nvim_create_user_command("CoppyRelativePath", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

vim.api.nvim_create_user_command("CopyCurrentDiagnostic", function()
	local diagnostics = vim.diagnostic.get(0)
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local current_diagnostic = nil

	for _, diag in ipairs(diagnostics) do
		if diag.lnum == line then
			current_diagnostic = diag.message
			break
		end
	end

	if current_diagnostic then
		vim.fn.setreg("+", current_diagnostic)
		print("Copy diagnostics to clipboard!")
	else
		print("Not found diagnostics at current cursor")
	end
end, {})

vim.api.nvim_create_user_command("FlutterLspRestartSmart", function()
	vim.cmd("LspRestart")

	vim.defer_fn(function()
		require("user.core.utils").attach_dartls_to_all_buffers()
	end, 1000)
end, { desc = "Restart LSP and re-attach all dart buffers" })

vim.api.nvim_create_user_command("GitBlameCopyGitHubURL", function()
	local current_file = vim.fn.expand("%")
	local line_number = vim.fn.line(".")

	local current_branch = vim.fn.system("git branch --show-current"):gsub("\n", "")

	local remote_url = vim.fn.system("git config --get remote.origin.url"):gsub("\n", "")

	local github_url
	if remote_url:match("^git@") then
		github_url = remote_url:gsub("git@[^:]+:", "https://github.com/")
		github_url = github_url:gsub("%.git$", "")
	else
		github_url = remote_url:gsub("https://[^/]+/", "https://github.com/")
		github_url = github_url:gsub("%.git$", "")
	end

	local final_url = string.format("%s/blob/%s/%s#L%d", github_url, current_branch, current_file, line_number)

	vim.fn.setreg("+", final_url)
	print("Copied: " .. final_url)
end, {})

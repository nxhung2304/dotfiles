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

require("user.core.bootstrap_lazy")

if vim.g.vscode then
	require("code.options")
	require("lazy").setup({
		spec = {
			{ import = "code.plugins" },
		},
		change_detection = { enabled = false },
	})
else
	require("lazy").setup({
		spec = {
			{ import = "user.plugins" },
		},
		change_detection = { enabled = false },
	})

	require("user.core")
end

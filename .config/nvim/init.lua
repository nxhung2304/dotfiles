require("user.core.bootstrap_lazy")

if vim.g.shadowvim then
	require("xcode.keymaps")
	require("lazy").setup({
		spec = {
			{ import = "xcode.plugins" },
		},
		change_detection = { enabled = false },
	})
elseif vim.g.vscode then
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
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#61afef", bold = true })
		vim.api.nvim_set_hl(0, "FloatTitle", { fg = "#e06c75", bold = true })
		vim.api.nvim_set_hl(0, "AvanteSeparator", { fg = "#5c6370", italic = true })

		vim.api.nvim_set_hl(0, "AvanteChatSection", { bg = "#2c323c", fg = "#abb2bf" })
		vim.api.nvim_set_hl(0, "AvanteFileSection", { bg = "#282c34", fg = "#98c379" })
		vim.api.nvim_set_hl(0, "AvanteAskSection", { bg = "#21252b", fg = "#e5c07b" })
	end,
})

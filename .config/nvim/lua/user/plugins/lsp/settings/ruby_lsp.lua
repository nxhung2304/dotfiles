return {
	init_options = {
		formatter = "auto",
		linters = { "rubocop" },
		addonSettings = {
			["Ruby LSP Rails"] = {
				enablePendingMigrationsPrompt = false,
			},
		},
	},
	settings = {
		rubyLsp = {
			codeLens = true,
			inlayHints = true,
		},
	},
	-- Neovim 0.11+ native LSP: use `root_markers`, not lspconfig's `util.root_pattern`.
	-- A root_pattern function has the signature fun(path)->path and never calls the
	-- `on_dir` callback that vim.lsp.config expects, so ruby_lsp would never start.
	root_markers = { "Gemfile", ".git" },
}

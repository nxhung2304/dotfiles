return {
	init_options = {
		enabled_features = {
			"rails",
		},
		formatter = "auto",
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
			rails = {
				enable = true,
			},
		},
	},
	root_dir = require("lspconfig").util.root_pattern("Gemfile", ".git", "config", "test", "spec"),
}

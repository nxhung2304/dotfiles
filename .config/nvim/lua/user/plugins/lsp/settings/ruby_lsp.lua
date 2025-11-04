return {
	init_options = {
		-- Enable Rails-specific features (từ ruby-lsp-rails)
		enabled_features = {
			"rails", -- Bật Rails add-on, hỗ trợ test discovery
		},
		-- Hoặc config chi tiết hơn nếu cần
		formatter = "auto", -- Sử dụng RuboCop nếu có
	},
	settings = {
		rubyLsp = {
			-- Enable code lenses cho tests (hiển thị "Run Test" trên method)
			codeLens = true,
			-- Hiển thị inlay hints cho test assertions, v.v.
			inlayHints = true,
			-- Rails-specific: Enable test routing (goto test file)
			rails = {
				enable = true,
			},
		},
	},
	-- Root dir detect Rails (Gemfile, config/routes.rb)
	root_dir = require("lspconfig").util.root_pattern("Gemfile", ".git", "config", "test", "spec"),
}

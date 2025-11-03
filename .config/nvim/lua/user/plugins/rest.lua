return {
	"rest-nvim/rest.nvim",
	ft = "http", -- Tự động load khi mở file .http
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter",
			opts = function(_, opts)
				opts.ensure_installed = opts.ensure_installed or {}
				table.insert(opts.ensure_installed, "http")
			end,
		},
		{
			"j-hui/fidget.nvim",
			tag = "legacy",
			opts = {
				notification = {
					window = { winblend = 0 },
				},
			},
		},
	},
	opts = {
		rocks = {
			hererocks = true,
		},
	},
}

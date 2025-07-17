local rest_layout = require("user.plugins.rest.rest_layout")
local rest_templates = require("user.plugins.rest.main")

return {
	"rest-nvim/rest.nvim",
	ft = {
		"http",
		"rest_nvim_result",
	},
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			table.insert(opts.ensure_installed, "http")
		end,
	},
	keys = {
		{ "<leader>rr", "<cmd>Rest run<cr>", desc = "Run request under cursor", ft = "http" },
		{ "<leader>rl", "<cmd>Rest last<cr>", desc = "Run last request", ft = "http" },
		{ "<leader>ro", "<cmd>Rest open<cr>", desc = "Open result pane", ft = "http" },
		{ "<leader>re", "<cmd>Rest env show<cr>", desc = "Show environment", ft = "http" },
		{ "<leader>rs", "<cmd>Rest env select<cr>", desc = "Select environment", ft = "http" },
		{ "<leader>rc", "<cmd>Rest cookies<cr>", desc = "Edit cookies", ft = "http" },
		{ "<leader>rL", "<cmd>Rest logs<cr>", desc = "View logs", ft = "http" },

		{ "<leader>rt", rest_layout.toggle_rest_layout, desc = "Toggle Rest Layout" },
		{ "<leader>rn", rest_templates.select_template, desc = "New REST template" },
		{ "<leader>rp", rest_templates.setup_rest_project, desc = "Setup REST project" },
	},
	config = function()
		vim.g.rest_nvim = {
			ui = {
				winbar = true,
				keybinds = {
					prev = "H",
					next = "L",
				},
			},
			request = {
				skip_ssl_verification = false,
			},
			response = {
				hooks = {
					format = true,
				},
			},
			cookies = {
				enable = true,
			},
		}
	end,
}

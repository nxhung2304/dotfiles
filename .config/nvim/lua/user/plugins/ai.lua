return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = {
					enabled = true,
					auto_trigger = true,
					debounce = 75,
					keymap = {
						accept = "<Tab>",
						accept_word = "<C-Right>",
						accept_line = "<C-j>",
						next = "<C-n>",
						prev = "<C-p>",
						dismiss = "<C-c>",
					},
				},
				panel = {
					enabled = true,
					auto_refresh = false,
					keymap = {
						jump_prev = "[[",
						jump_next = "]]",
						accept = "<CR>",
						refresh = "gr",
						open = "<M-CR>",
					},
					layout = {
						position = "bottom", -- | top | left | right
						ratio = 0.4,
					},
				},
				filetypes = {
					yaml = false,
					markdown = false,
					help = false,
					gitcommit = false,
					gitrebase = false,
					hgcommit = false,
					svn = false,
					cvs = false,
					["."] = false,
				},
			})
		end,
	},
	{
		"olimorris/codecompanion.nvim",
		opts = {
			display = {
				chat = {
					window = {
						layout = "vertical", -- hoặc "horizontal"
						border = "single",
						title = "Chatbox",
					},
				},
			},
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			-- {
			-- 	"OXY2DEV/markview.nvim",
			-- 	lazy = false,
			-- 	opts = {
			-- 		preview = {
			-- 			filetypes = { "codecompanion" },
			-- 			ignore_buftypes = {},
			-- 		},
			-- 	},
			-- },
		},
		keys = {
			{ mode = "n", "<leader>ao", "<cmd>CodeCompanion<cr>", desc = "Code Companion" },
			{ mode = "n", "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "Actions" },
			{ mode = "n", "<leader>ac", "<cmd>CodeCompanionChat<cr>", desc = "Chat" },
			{ mode = "v", "<leader>ao", "<cmd>CodeCompanion<cr>", desc = "Code Companion" },
			{ mode = "v", "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "Actions" },
			{ mode = "v", "<leader>ac", "<cmd>CodeCompanionChat<cr>", desc = "Chat" },
		},
	},
}

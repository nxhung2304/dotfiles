return {
	{
		"zbirenbaum/copilot.lua",
		event = { "InsertEnter", "CmdlineEnter" },
		config = function()
			require("copilot").setup({
				disable_limit_reached_message = true,
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
						position = "bottom",
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
			vim.keymap.set("n", "<leader>ct", function()
				require("copilot.suggestion").toggle_auto_trigger()
				local is_auto = require("copilot.suggestion").is_auto_trigger_enabled()
				vim.cmd.echo("Copilot auto-trigger: " .. (is_auto and "ON" or "OFF"))
			end, { desc = "Toggle Copilot auto-trigger" })
		end,
	},
	{
		"olimorris/codecompanion.nvim",
		keys = {
			{ "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle chat" },
			{ "<leader>aa", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add selection to chat" },
			{ "<leader>ai", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "Inline assist" },
			{ "<leader>ap", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "Action picker" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			{
				"MeanderingProgrammer/render-markdown.nvim",
				ft = { "markdown", "codecompanion" },
			},
			{
				"echasnovski/mini.diff",
				config = function()
					require("mini.diff").setup({ view = { style = "sign" } })
				end,
			},
		},
		config = function()
			require("codecompanion").setup({
				strategies = {
					chat = { adapter = "claude_code" },
					inline = { adapter = "copilot" },
					agent = { adapter = "claude_code" },
				},
				display = {
					chat = {
						render_headers = true,
						show_references = true,
						show_settings = false,
					},
					diff = {
						provider = "mini_diff",
					},
				},
			})
		end,
	},
}

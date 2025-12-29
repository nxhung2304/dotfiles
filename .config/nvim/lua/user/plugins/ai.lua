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
		tag = "v17.33.0",
		cmd = { "CodeCompanionChat", "CodeCompanionActions" },
		opts = {
			strategies = {
				inline = {
					enabled = true,
					marks = {
						last = "●",
					},
					format = {
						inline = { pattern = "^%s*<<<\\s*(.-)\\s*>>>", group = "Statement" },
					},
				},
			},
			display = {
				render = {
					inline = {
						layout = "float",
					},
				},
			},
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"ravitemer/mcphub.nvim",
			{
				"OXY2DEV/markview.nvim",
				lazy = false,
				opts = {
					preview = {
						filetypes = { "markdown", "codecompanion" },
						ignore_buftypes = {},
					},
				},
			},
		},
		keys = {
			{
				"<leader>ac",
				"<cmd>CodeCompanionChat Toggle<cr>",
				mode = { "n", "v" },
				desc = "Toggle CodeCompanion Chat",
			},
			{
				"<leader>aa",
				"<cmd>CodeCompanionActions<cr>",
				mode = { "n", "v" },
				desc = "CodeCompanion Actions Palette",
			},
			{ "<leader>av", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add visual selection to Chat" },
		},
	},
}

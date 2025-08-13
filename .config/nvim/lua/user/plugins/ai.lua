return {
	{
		"olimorris/codecompanion.nvim",
		opts = {},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"ravitemer/mcphub.nvim",
			{
				"echasnovski/mini.diff",
				config = function()
					local diff = require("mini.diff")
					diff.setup({
						source = diff.gen_source.none(),
					})
				end,
			},
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
			{
				"HakonHarnes/img-clip.nvim",
				opts = {
					filetypes = {
						codecompanion = {
							prompt_for_file_name = false,
							template = "[Image]($FILE_PATH)",
							use_absolute_path = true,
						},
					},
				},
			},
		},
		config = function()
			require("codecompanion").setup({
				extensions = {
					mcphub = {
						callback = "mcphub.extensions.codecompanion",
						opts = {
							make_vars = true,
							make_slash_commands = true,
							show_result_in_chat = true,
						},
					},
				},

				strategies = {
					chat = {
						adapter = "gemini",
					},
					inline = {
						adapter = "gemini",
						keymaps = {
							accept_change = {
								modes = { n = "ga" },
								description = "Accept the suggested change",
							},
							reject_change = {
								modes = { n = "gr" },
								opts = { nowait = true },
								description = "Reject the suggested change",
							},
						},
					},
				},

				display = {
					action_palette = {
						width = 95,
						height = 10,
						prompt = "Prompt ", -- Prompt used for interactive LLM calls
						provider = "default", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
						opts = {
							show_default_actions = true, -- Show the default actions in the action palette?
							show_default_prompt_library = true, -- Show the default prompt library in the action palette?
							title = "CodeCompanion actions", -- The title of the action palette
						},
					},

					diff = {
						provider = "mini_diff", -- Hiển thị diff
						show_signs = true,
					},
					inline = {
						show_virtual_text = true, -- Hiển thị virtual text
					},
				},
				inline = {
					show_diff = true,
					show_help = true, -- Hiển thị ga/gr hints
				},
			})
		end,
		keys = {
			{ "<leader>Ao", "<cmd>CodeCompanion<cr>", desc = "Prompt" },
			{ "<leader>Aa", "<cmd>CodeCompanionActions<cr>", desc = "Actions" },
			{ "<leader>Ac", "<cmd>CodeCompanionChat<cr>", desc = "Chat" },
		},
	},
}

return {
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
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
				"ravitemer/mcphub.nvim",
				dependencies = { "nvim-lua/plenary.nvim" },
				cmd = "MCPHub",
				build = "npm install -g mcp-hub@latest",
				config = function()
					require("mcphub").setup({
						port = 3000,
						config = vim.fn.expand("~/.config/mcphub/servers.json"),
						workspace_configs = { vim.fn.expand(".mcphub/servers.json") },
						extensions = {
							codecompanion = {
								show_result_in_chat = true,
								make_vars = true,
								make_slash_commands = true,
							},
						},
					})
				end,
			},
			{ "echasnovski/mini.diff", version = false },
		},
		opts = {
			strategies = {
				chat = {
					adapter = "gemini",
					roles = {
						llm = "Gemini",
						user = "Namiez",
					},
					opts = {
						auto_scroll = true,
						fold_code = true,
						show_settings = true,
						show_token_count = true,
					},
					slash_commands = {
						["buffer"] = {
							callback = "strategies.chat.slash_commands.buffer",
							description = "Insert open buffers",
							opts = {
								provider = "telescope",
							},
						},
						["file"] = {
							callback = "strategies.chat.slash_commands.file",
							description = "Insert a file",
							opts = {
								provider = "telescope",
							},
						},
					},
					tools = {
						["mcp"] = {
							callback = function()
								return require("mcphub.extensions.codecompanion")
							end,
							description = "Call tools and resources from MCP servers",
							opts = { requires_approval = true },
						},
					},
				},
				inline = {
					adapter = "gemini",
					opts = {
						placement = "cursor",
						diff = {
							enabled = true,
							close_chat_at = 240,
							layout = "vertical",
							opts = {
								"internal",
								"filler",
								"closeoff",
								"hiddenoff",
								"followwrap",
							},
						},
					},
				},
			},
			opts = {
				log_level = "DEBUG",
			},
			display = {
				diff = {
					enabled = true,
					provider = "mini_diff", -- mini_diff|split|inline
					close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...

					-- Options for the split diff provider
					layout = "vertical", -- vertical|horizontal split
					opts = {
						"internal",
						"filler",
						"closeoff",
						"algorithm:histogram", -- https://adamj.eu/tech/2024/01/18/git-improve-diff-histogram/
						"indent-heuristic", -- https://blog.k-nut.eu/better-git-diffs
						"followwrap",
						"linematch:120",
					},

					diff_signs = {
						signs = {
							text = "▌", -- Sign text for normal changes
							reject = "✗", -- Sign text for rejected changes in super_diff
							highlight_groups = {
								addition = "DiagnosticOk",
								deletion = "DiagnosticError",
								modification = "DiagnosticWarn",
							},
						},
						-- Super Diff options
						icons = {
							accepted = " ",
							rejected = " ",
						},
						colors = {
							accepted = "DiagnosticOk",
							rejected = "DiagnosticError",
						},
					},
				},
			},
			extensions = {
				mcphub = {
					callback = "mcphub.extensions.codecompanion",
					opts = {
						make_tools = true,
						show_server_tools_in_chat = true,
						show_result_in_chat = true,
						make_vars = true,
						make_slash_commands = true,
					},
				},
			},
		},
		keys = {
			{ "<leader>Ac", "<cmd>CodeCompanionChat<cr>", desc = "Open Chat" },
			{ "<leader>Aa", "<cmd>CodeCompanionActions<cr>", desc = "Open Actions" },

			{ "<leader>Ac", "<cmd>CodeCompanionChat<cr>", desc = "Open Chat", mode = { "v" } },
			{ "<leader>Aa", "<cmd>CodeCompanionActions<cr>", desc = "Open Actions", mode = { "v" } },
		},
	},
}

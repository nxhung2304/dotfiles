return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.1",
		cmd = "Telescope",
		opts = {
			defaults = {
				file_ignore_patterns = { "node_modules", ".git/" },
				selection_strategy = "reset",
				case_mode = "ignore_case",
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
				},
				mappings = {
					i = {
						["<C-w>"] = function()
							vim.api.nvim_input("<C-S-w>")
						end,
						["<C-u>"] = function()
							vim.api.nvim_input("<C-u>")
						end,
						["<C-a>"] = function()
							vim.api.nvim_input("<Home>")
						end,
						["<C-e>"] = function()
							vim.api.nvim_input("<End>")
						end,
					},
				},
			},

			pickers = {
				colorscheme = {
					enable_preview = true,
				},
				oldfiles = {
					cwd_only = true,
				},
				find_files = {
					find_command = { "rg", "--files", "--iglob", "!.git", "--hidden" },
					case_mode = "ignore_case",
				},
			},
			extensions = {
				smart_open = {
					match_algorithm = "fzf",
					cwd_only = true,
					ignore_patterns = { "*.git/*", "*/tmp/*", ".idea/" },
				},
			},
		},
		keys = {
			{
				"<leader>sf",
				"<cmd>Telescope find_files<cr>",
				desc = "Find files",
			},
			{ "<leader>sr", "<cmd>Telescope oldfiles<cr>", desc = "Find oldfiles" },
			{ "<leader>sB", "<cmd>Telescope git_branches<cr>", desc = "Find branches" },
			{ "<leader>sb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
			{ "<leader>sw", "<cmd>Telescope grep_string<cr>", desc = "Find current cursor" },
		},
	},
}

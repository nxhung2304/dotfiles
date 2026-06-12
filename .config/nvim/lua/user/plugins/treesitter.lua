return {
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			max_lines = 3,
			trim_scope = "outer",
			mode = "cursor",
		},
		config = function(_, opts)
			require("treesitter-context").setup(opts)
			vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "#555555" })
			vim.api.nvim_set_hl(0, "TreesitterContextLineNumberBottom", { underline = true, sp = "#555555" })

			-- box shadow: dim the context slightly and set winblend on its float window
			vim.api.nvim_create_autocmd("WinNew", {
				callback = function()
					vim.schedule(function()
						for _, win in ipairs(vim.api.nvim_list_wins()) do
							local cfg = vim.api.nvim_win_get_config(win)
							if cfg.zindex and cfg.zindex == 20 and cfg.relative ~= "" then
								vim.wo[win].winblend = 15
							end
						end
					end)
				end,
			})
		end,
		keys = {
			{
				"[C",
				function()
					require("treesitter-context").go_to_context(vim.v.count1)
				end,
				desc = "Jump to context",
				silent = true,
			},
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"tree-sitter/tree-sitter-embedded-template",
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			require("nvim-treesitter").setup({
        ensure_installed = {
						"bash",
						"css",
						"dart",
						"embedded_template",
						"html",
						"javascript",
						"json",
						"lua",
						"markdown",
						"markdown_inline",
						"ruby",
						"typescript",
						"tsx",
						"vim",
						"vimdoc",
						"yaml",
					},
				textobjects = {
					select = {
						enable = true,

						-- Automatically jump forward to textobj, similar to targets.vim
						lookahead = true,

						keymaps = {
							-- You can use the capture groups defined in textobjects.scm
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							-- You can optionally set descriptions to the mappings (used in the desc parameter of
							-- nvim_buf_set_keymap) which plugins like which-key display
							["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
							-- You can also use captures from other query groups like `locals.scm`
							["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
						},
						-- You can choose the select mode (default is charwise 'v')
						--
						-- Can also be a function which gets passed a table with the keys
						-- * query_string: eg '@function.inner'
						-- * method: eg 'v' or 'o'
						-- and should return the mode ('v', 'V', or '<c-v>') or a table
						-- mapping query_strings to modes.
						selection_modes = {
							["@parameter.outer"] = "v", -- charwise
							["@function.outer"] = "V", -- linewise
							["@class.outer"] = "<c-v>", -- blockwise
						},
						-- If you set this to `true` (default is `false`) then any textobject is
						-- extended to include preceding or succeeding whitespace. Succeeding
						-- whitespace has priority in order to act similarly to eg the built-in
						-- `ap`.
						--
						-- Can also be a function which gets passed a table with the keys
						-- * query_string: eg '@function.inner'
						-- * selection_mode: eg 'v'
						-- and should return true of false
						include_surrounding_whitespace = true,
					},
					move = {
						enable = true,
						goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
						goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
						goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
						goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
					},
				},
				indent = { enable = true, disable = { "dart" } },
			})
		end,
	},
}

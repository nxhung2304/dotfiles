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

			local function set_context_hl()
				local context_bg = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false }).bg
				local line_number_fg = vim.api.nvim_get_hl(0, { name = "LineNr", link = false }).fg
				vim.api.nvim_set_hl(0, "TreesitterContext", { bg = context_bg })
				vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { bg = context_bg, fg = line_number_fg })
			end
			set_context_hl()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = set_context_hl })
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
			local parsers = {
				"bash",
				"css",
				"dart",
				"embedded_template",
				"go",
				"gomod",
				"gosum",
				"gotmpl",
				"gowork",
				"groovy",
				"html",
				"java",
				"javascript",
				"json",
				"kotlin",
				"lua",
				"markdown",
				"markdown_inline",
				"ruby",
				"swift",
				"templ",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"xml",
				"yaml",
			}

			require("nvim-treesitter").setup({
        ensure_installed = parsers,
				indent = { enable = true, disable = { "dart" } },
			})
			require("nvim-treesitter").install(parsers)

			require("nvim-treesitter-textobjects").setup({
				select = {
					-- Automatically jump forward to textobj, similar to targets.vim
					lookahead = true,
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
					set_jumps = true,
				},
			})

			local select_textobjects = require("nvim-treesitter-textobjects.select")
			local select_keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				{ lhs = "ac", query = "@class.outer", group = "textobjects", desc = "Select outer part of a class region" },
				{ lhs = "ic", query = "@class.inner", group = "textobjects", desc = "Select inner part of a class region" },
				-- You can also use captures from other query groups like `locals.scm`
				{ lhs = "as", query = "@local.scope", group = "locals", desc = "Select language scope" },
			}
			for _, mapping in ipairs(select_keymaps) do
				vim.keymap.set({ "x", "o" }, mapping.lhs, function()
					select_textobjects.select_textobject(mapping.query, mapping.group)
				end, { desc = mapping.desc })
			end

			local move_textobjects = require("nvim-treesitter-textobjects.move")
			local all_modes = { "n", "x", "o" }
			local visual_and_operator_modes = { "x", "o" }
			local move_keymaps = {
				{ lhs = "]f", action = "goto_next_start", query = "@function.outer", modes = visual_and_operator_modes },
				{ lhs = "]c", action = "goto_next_start", query = "@class.outer", modes = all_modes, keeps_diff_jump = true },
				{ lhs = "]F", action = "goto_next_end", query = "@function.outer", modes = all_modes },
				{ lhs = "]C", action = "goto_next_end", query = "@class.outer", modes = all_modes },
				{ lhs = "[f", action = "goto_previous_start", query = "@function.outer", modes = visual_and_operator_modes },
				{ lhs = "[c", action = "goto_previous_start", query = "@class.outer", modes = all_modes, keeps_diff_jump = true },
				{ lhs = "[F", action = "goto_previous_end", query = "@function.outer", modes = all_modes },
				{ lhs = "[C", action = "goto_previous_end", query = "@class.outer", modes = visual_and_operator_modes },
			}
			for _, mapping in ipairs(move_keymaps) do
				vim.keymap.set(mapping.modes, mapping.lhs, function()
					if mapping.keeps_diff_jump and vim.wo.diff then
						vim.cmd("normal! " .. vim.v.count1 .. mapping.lhs)
						return
					end
					move_textobjects[mapping.action](mapping.query, "textobjects")
				end, { desc = mapping.action .. " " .. mapping.query })
			end

			local highlighted_filetypes = { "groovy", "java", "kotlin", "swift", "xml" }
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("TreesitterMobileHighlight", { clear = true }),
				pattern = highlighted_filetypes,
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
				end,
			})
			if vim.tbl_contains(highlighted_filetypes, vim.bo.filetype) then
				pcall(vim.treesitter.start)
			end
		end,
	},
}

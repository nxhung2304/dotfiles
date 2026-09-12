-- Database client: vim-dadbod (engine) + vim-dadbod-ui (drawer UI) and
-- vim-dadbod-completion (table/column completion inside SQL buffers).
-- Connections live in ~/.local/share/db_ui (added with `A` in the drawer),
-- or in the DBUI_* / g:dbs variables.
return {
	{
		"tpope/vim-dadbod",
		cmd = { "DB", "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
	},
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			"tpope/vim-dadbod",
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" } },
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_show_database_icon = 1
			vim.g.db_ui_win_position = "left"
			vim.g.db_ui_winwidth = 35
			-- Keep generated queries and saved queries out of the repo.
			vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui_queries"
			vim.g.db_ui_tmp_query_location = vim.fn.stdpath("data") .. "/db_ui_tmp"
			-- Run the query under the cursor without needing a visual selection.
			vim.g.db_ui_execute_on_save = 0
		end,
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "sql", "mysql", "plsql" },
				callback = function()
					require("cmp").setup.buffer({
						sources = {
							{ name = "vim-dadbod-completion" },
							{ name = "buffer" },
						},
					})
				end,
			})

			-- The drawer is a plain buffer; keep it clean of numbers/signs.
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "dbui",
				callback = function()
					vim.opt_local.number = false
					vim.opt_local.relativenumber = false
					vim.opt_local.signcolumn = "no"
				end,
			})
		end,
		keys = {
			{ "<leader>Du", "<cmd>DBUIToggle<cr>", desc = "Toggle DB UI" },
			{ "<leader>Da", "<cmd>DBUIAddConnection<cr>", desc = "Add DB connection" },
			{ "<leader>Df", "<cmd>DBUIFindBuffer<cr>", desc = "Find DB buffer" },
			{ "<leader>Dr", "<cmd>DBUIRenameBuffer<cr>", desc = "Rename DB buffer" },
			{ "<leader>Dl", "<cmd>DBUILastQueryInfo<cr>", desc = "Last query info" },
		},
	},
}

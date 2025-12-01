local Utils = require("user.core.utils")
local map = Utils.keymap

return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			on_attach = function(_)
				local gs = require("gitsigns")

				-- Navigation
				map("n", "]g", gs.next_hunk, { desc = "Next hunk" })
				map("n", "[g", gs.prev_hunk, { desc = "Prev hunk" })

				-- Actions
				map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage hunk" })
				map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset hunk" })
				map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
				map("n", "<leader>gl", gs.setqflist, { desc = "Show changes in qf" })
				map("n", "<leader>gc", "<cmd>GitBlameCopyGitHubURL<cr>", { desc = "Copy file URL Remote" })
			end,

			-- Blame config
			current_line_blame = true,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
				delay = 100,
				ignore_whitespace = false,
				virt_text_priority = 100,
				use_focus = true,
			},
			current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
		},
	},
	{
		"NeogitOrg/neogit",
		cmd = "Neogit",
		opts = {
			integrations = {
				telescope = true,
			},
			disable_line_numbers = false,
			disable_relative_line_numbers = false,
		},
		keys = {
			{ "<Leader>go", "<cmd>Neogit<cr>", desc = "Open Neogit" },
		},
		config = function(opts)
			require("neogit").setup(opts)

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "NeogitStatus", "NeogitCommitMessage", "NeogitPopup" },
				callback = function()
					vim.wo.number = true
					vim.wo.relativenumber = true
				end,
			})
		end,
	},
	{
		"esmuellert/vscode-diff.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		config = function()
			require("vscode-diff").setup({
				-- Highlight configuration
				highlights = {
					-- Line-level: accepts highlight group names or hex colors (e.g., "#2ea043")
					line_insert = "DiffAdd", -- Line-level insertions
					line_delete = "DiffDelete", -- Line-level deletions

					-- Character-level: accepts highlight group names or hex colors
					-- If specified, these override char_brightness calculation
					char_insert = nil, -- Character-level insertions (nil = auto-derive)
					char_delete = nil, -- Character-level deletions (nil = auto-derive)

					-- Brightness multiplier (only used when char_insert/char_delete are nil)
					-- nil = auto-detect based on background (1.4 for dark, 0.92 for light)
					char_brightness = nil, -- Auto-adjust based on your colorscheme
				},

				-- Diff view behavior
				diff = {
					disable_inlay_hints = true, -- Disable inlay hints in diff windows for cleaner view
					max_computation_time_ms = 5000, -- Maximum time for diff computation (VSCode default)
				},

				-- Keymaps in diff view
				keymaps = {
					view = {
						quit = "q", -- Close diff tab
						toggle_explorer = "<leader>b", -- Toggle explorer visibility (explorer mode only)
						next_hunk = "]c", -- Jump to next change
						prev_hunk = "[c", -- Jump to previous change
						next_file = "]f", -- Next file in explorer mode
						prev_file = "[f", -- Previous file in explorer mode
					},
					explorer = {
						select = "<CR>", -- Open diff for selected file
						hover = "K", -- Show file diff preview
						refresh = "R", -- Refresh git status
					},
				},
			})
		end,
	},
}

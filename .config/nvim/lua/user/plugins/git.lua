local Utils = require("user.core.utils")
local map = Utils.keymap

return {
	{
		"esmuellert/codediff.nvim",
		cmd = "CodeDiff",
		opts = {
			diff = {
				layout = "side-by-side",
				jump_to_first_change = true,
				cycle_next_hunk = true,
				cycle_next_file = true,
			},
			explorer = {
				position = "left",
				width = 40,
				auto_refresh = true,
				view_mode = "list",
			},
			keymaps = {
				view = {
					quit = "q",
					next_hunk = "]g",
					prev_hunk = "[g",
					next_file = "]f",
					prev_file = "[f",
					toggle_stage = "-",
					toggle_layout = "t",
					show_help = "g?",
				},
			},
		},
	},
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
		lazy = true,
		dependencies = {
			"m00qek/baleia.nvim", -- optional
		},
		cmd = "Neogit",
		keys = {
			{ "<leader>go", "<cmd>Neogit<cr>", desc = "Show Neogit UI" },
		},
	},
}

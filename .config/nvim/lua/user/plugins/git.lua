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
				auto_refresh = true,
				view_mode = "list",
			},
			keymaps = {
				view = {
					quit = "q",
					next_hunk = "]c",
					prev_hunk = "[c",
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
				map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Stage hunk (visual)" })
				map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
				map("n", "<leader>gS", gs.stage_buffer, { desc = "Stage buffer" })
				map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset hunk" })
				map("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Reset hunk (visual)" })
				map("n", "<leader>gR", gs.reset_buffer, { desc = "Reset buffer" })
				map("n", "<leader>gp", gs.preview_hunk_inline, { desc = "Preview hunk" })
				map("n", "<leader>gd", gs.diffthis, { desc = "Diff this" })
				map("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "Toggle line blame" })
				map("n", "<leader>gL", function() gs.blame_line({ full = true }) end, { desc = "Blame line (full)" })
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

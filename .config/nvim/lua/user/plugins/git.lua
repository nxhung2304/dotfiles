local Utils = require("user.core.utils")
local map = Utils.keymap

local function toggle_diffview(cmd)
	if next(require("diffview.lib").views) == nil then
		vim.cmd(cmd)
	else
		vim.cmd("DiffviewClose")
	end
end

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
		"akinsho/git-conflict.nvim",
		event = "BufReadPre",
		opts = function()
			vim.cmd([[
        hi GitconflictCurrent guibg=#307365 ctermbg=4 guifg=#ffffff
        hi GitconflictIncoming guibg=#2F628D ctermbg=4 guifg=#ffffff
      ]])

			return {
				default_mappings = true, -- disable buffer local mapping created by this plugin
				disable_diagnostics = false, -- This will disable the diagnostics in a buffer whilst it is conflicted
				highlights = { -- They must have background color, otherwise the default color will be used
					incoming = "GitconflictIncoming",
					current = "GitconflictCurrent",
				},
			}
		end,
		keys = {
			{
				"<Leader>Cc",
				"<cmd>GitConflictChooseOurs<cr>",
				desc = "Select current",
			},
			{ "<Leader>Ci", "<cmd>GitConflictChooseTheirs<cr>", desc = "Select incomming" },
			{ "<Leader>Cb", "<cmd>GitConflictChooseBoth<cr>", desc = "Select both" },
			"<Leader>Cn",
			"<cmd>GitConflictNextConflict<cr>",
			desc = "Next",
			{ "<Leader>Cp", "<cmd>GitConflictPrevConflict<cr>", desc = "Previous" },
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
		"sindrets/diffview.nvim",
		command = "DiffviewOpen",
		keys = {
			{
				"<leader>gd",
				function()
					toggle_diffview("DiffviewOpen")
				end,
				desc = "Diff Index",
			},
			{
				"<leader>gf",
				function()
					toggle_diffview("DiffviewFileHistory %")
				end,
				desc = "Open diffs for current File",
			},
		},
	},
}

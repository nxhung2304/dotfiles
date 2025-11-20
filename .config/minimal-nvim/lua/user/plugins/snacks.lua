return {
	"folke/snacks.nvim",
	opts = {
		animate = { enabled = true },
		scope = { enabled = true },
		scroll = { enabled = true },
		bigfile = { enabled = true },
		bufdelete = { enabled = true },
		dim = { enabled = true },
		picker = {
			enabled = true,
			sources = {
				explorer = {
					hidden = true,
					follow_current_file = true,
				},
			},
		},
		indent = { enabled = true },
		explorer = { enabled = true },
		statuscolumn = { enabled = true },
	},
	keys = {
		-- Search
		{
			"<leader>sf",
			function()
				Snacks.picker.smart()
			end,
			desc = "Find files",
		},
		{
			"<leader>sr",
			function()
				Snacks.picker.recent()
			end,
			desc = "Find oldfiles",
		},
		{
			"<leader>sB",
			function()
				Snacks.picker.git_branches()
			end,
			desc = "Find branches",
		},
		{
			"<leader>sb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Find buffers",
		},
		-- Github
		{
			"<leader>gi",
			function()
				Snacks.picker.gh_issue()
			end,
			desc = "GitHub Issues (open)",
		},
		{
			"<leader>gI",
			function()
				Snacks.picker.gh_issue({ state = "all" })
			end,
			desc = "GitHub Issues (all)",
		},
		{
			"<leader>gp",
			function()
				Snacks.picker.gh_pr()
			end,
			desc = "GitHub Pull Requests (open)",
		},
		{
			"<leader>gP",
			function()
				Snacks.picker.gh_pr({ state = "all" })
			end,
			desc = "GitHub Pull Requests (all)",
		},
		-- Explorer
		{
			"<leader>e",
			function()
				Snacks.explorer()
			end,
			desc = "Open explorer",
		},
	},
}

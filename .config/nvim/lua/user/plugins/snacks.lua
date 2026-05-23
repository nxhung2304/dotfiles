return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		bigfile = { enabled = true },
		indent = { enabled = true },
		scope = { enabled = true },
		gh = {},
		image = {
			enabled = true,
			backend = "kitty",
			max_width_window_percentage = 95,
			max_height_window_percentage = 95,
			scale = 1.2,
		},
		input = { enabled = true },
		notifier = {
			enabled = true,
			timeout = 3000,
			style = "compact",
			top_down = false,
		},
		picker = {
			enabled = true,
			layout = {
				preset = "dropdown",
				preview = false,
			},
			sources = {
				files = {
					hidden = true,
				},
			},
		},
		quickfile = { enabled = true },
		rename = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
	},
	keys = {
		-- Picker (replacing telescope)
		{
			"<leader>sf",
			function()
				Snacks.picker.files()
			end,
			desc = "Find files",
		},
		{
			"<leader>si",
			function()
				Snacks.picker.files({ cwd = "~/.config/nvim" })
			end,
			desc = "Find files in ~/.config/nvim",
		},
		{
			"<leader>sr",
			function()
				Snacks.picker.recent({ filter = { cwd = true } })
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
		{
			"<leader>sw",
			function()
				Snacks.picker.grep_word()
			end,
			desc = "Find current cursor",
			mode = { "n", "x" },
		},
		-- LSP (replacing aerial)
		{
			"<leader>uo",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "LSP Symbols",
		},
		-- Notifications
		{
			"<leader>un",
			function()
				Snacks.notifier.hide()
			end,
			desc = "Dismiss All Notifications",
		},
		{
			"<leader>um",
			function()
				Snacks.notifier.show_history()
			end,
			desc = "Show messages",
		},
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
	},
}

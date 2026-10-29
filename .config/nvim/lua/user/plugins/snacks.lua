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
			matcher = {
				smartcase = false,
				ignorecase = true,
			},
			sources = {
				files = {
					hidden = true,
					follow = true,
				},
				grep = {
					layout = { preset = "dropdown", preview = true },
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
				Snacks.picker.smart({ filter = { cwd = true } })
			end,
			desc = "Find files (smart)",
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
			desc = "Show Notification History",
		},
	},
}

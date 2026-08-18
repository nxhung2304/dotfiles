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
				},
			},
		},
		dashboard = {
			enabled = true,
			preset = {
				header = [[
 ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
 ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
 ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
 ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
 ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
				keys = {
					{ icon = "󰈞 ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
					{ icon = "󰈔 ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{ icon = "󰋚 ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent({ filter = { cwd = true } })" },
					{ icon = "󰊢 ", key = "g", desc = "Git status", action = ":Neogit" },
					{ icon = "󰒓 ", key = "c", desc = "Config", action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
					{ icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
					{ icon = "󰗼 ", key = "q", desc = "Quit", action = ":qa" },
				},
			},
			sections = {
				{ section = "header" },
				{
					section = "recent_files",
					title = "Recent Files",
					cwd = true,
					limit = 5,
					padding = 1,
				},
				{ section = "keys", gap = 1, padding = 1 },
				{ section = "startup" },
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
				Snacks.picker.smart()
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
				Snacks.win({
					text = vim.split(vim.fn.execute("messages"), "\n", { trimempty = true }),
					title = " Messages",
					width = 0.8,
					height = 0.6,
					border = "rounded",
					wo = { wrap = true },
				})
			end,
			desc = "Show Messages",
		},
	},
}

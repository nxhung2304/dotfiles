return {
	"folke/edgy.nvim",
	event = "VeryLazy",
	opts = {
		animate = {
			enabled = false,
		},
		right = {
			{
				title = "Outline symbols",
				ft = "aerial",
			},
			{
				ft = "log",
				title = "Flutter Log",
				size = { width = 0.25 },
				filter = function(buf)
					return vim.bo[buf].filetype == "log" and vim.api.nvim_buf_get_name(buf):match("flutter")
				end,
			},
		},
		left = {
			{
				title = "File Explorer",
				ft = "NvimTree",
				size = {
					width = 0.2,
				},
			},
			{
				ft = "flutterToolsOutline",
				title = "Flutter Outline",
				size = { width = 0.2 },
			},
			-- DAP UI Scopes
			{
				ft = "dapui_scopes",
				title = "Variables",
				size = { width = 0.2 },
			},
			-- DAP UI Stacks
			-- {
			-- 	ft = "dapui_stacks",
			-- 	title = "Call Stack",
			-- 	size = { width = 0.25 },
			-- },
			-- DAP UI Breakpoints
			{
				ft = "dapui_breakpoints",
				title = "Breakpoints",
				size = { width = 0.2 },
			},
			-- DAP UI Watches
			-- {
			-- 	ft = "dapui_watches",
			-- 	title = "Watches",
			-- 	size = { width = 0.25 },
			-- },
		},
		bottom = {
			-- Flutter log
			-- {
			-- 	ft = "log",
			-- 	title = "Flutter Log",
			-- 	size = { height = 0.3 },
			-- 	filter = function(buf)
			-- 		return vim.bo[buf].filetype == "log" and vim.api.nvim_buf_get_name(buf):match("flutter")
			-- 	end,
			-- },
			-- DAP Console
			-- {
			-- 	ft = "dap-console",
			-- 	title = "Debug Console",
			-- 	size = { height = 0.3 },
			-- },
			-- DAP REPL
			{
				ft = "dap-repl",
				title = "Debug REPL",
				size = { height = 0.1 },
				filter = function(buf)
					return vim.bo[buf].filetype == "dap-repl"
				end,
			},
			-- Terminal
			{
				ft = "terminal",
				title = "Terminal",
				size = { height = 0.3 },
				filter = function(buf)
					return vim.bo[buf].filetype == "terminal"
				end,
			},
			-- Messages
			{
				ft = "messages",
				title = "Messages",
				size = { height = 0.25 },
			},
		},
	},
	init = function()
		vim.opt.laststatus = 3
		vim.opt.splitkeep = "screen"

	end,
	keys = {
		-- Toggle panels
		{ "<leader>we", "<cmd>lua require('edgy').toggle()<cr>", desc = "Toggle Edgy" },
		{ "<leader>wl", "<cmd>lua require('edgy').toggle('left')<cr>", desc = "Toggle Left Panel" },
		{ "<leader>wr", "<cmd>lua require('edgy').toggle('right')<cr>", desc = "Toggle Right Panel" },
		{ "<leader>wb", "<cmd>lua require('edgy').toggle('bottom')<cr>", desc = "Toggle Bottom Panel" },

		-- Select panels
		{ "<leader>wsl", "<cmd>lua require('edgy').select('left')<cr>", desc = "Select Left Panel" },
		{ "<leader>wsr", "<cmd>lua require('edgy').select('right')<cr>", desc = "Select Right Panel" },
		{ "<leader>wsb", "<cmd>lua require('edgy').select('bottom')<cr>", desc = "Select Bottom Panel" },

		-- Go to main window
		{ "<leader>wm", "<cmd>lua require('edgy').goto_main()<cr>", desc = "Go to Main Window" },

		-- Debug layout shortcuts
		{
			"<leader>wd",
			function()
				require("edgy").open("left")
				require("edgy").open("bottom")
			end,
			desc = "Open Debug Layout",
		},

		{
			"<leader>wD",
			function()
				require("edgy").close("left")
				require("edgy").close("bottom")
				require("edgy").close("right")
			end,
			desc = "Close Debug Layout",
		},
	},
}

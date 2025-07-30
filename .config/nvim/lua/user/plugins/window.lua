return {
	"folke/edgy.nvim",
	event = "VeryLazy",
	opts = {
		animate = {
			enabled = false,
		},
		right = {
			{
				ft = "log",
				title = "Flutter Log",
				size = { width = 0.25 },
				filter = function(buf)
					return vim.bo[buf].filetype == "log" and not vim.api.nvim_buf_get_name(buf):match("flutter")
				end,
			},
			{
				ft = "rest_nvim_result",
				title = "API Response",
				size = { width = 0.5 },
				filter = function(buf)
					return vim.bo[buf].filetype == "rest_nvim_result"
				end,
			},
		},
		left = {
			{
				title = "Outline symbols",
				ft = "aerial",
				size = { width = 0.2 },
			},
			-- {
			-- 	title = "File Explorer",
			-- 	ft = "NvimTree",
			-- 	size = {
			-- 		width = 0.2,
			-- 	},
			-- },
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
			-- DAP UI Breakpoints
			{
				ft = "dapui_breakpoints",
				title = "Breakpoints",
				size = { width = 0.2 },
			},
		},
		bottom = {
			-- DAP REPL
			-- {
			-- 	ft = "dap-repl",
			-- 	title = "Debug REPL",
			-- 	size = { height = 0.2 },
			-- 	filter = function(buf)
			-- 		return vim.bo[buf].filetype == "dap-repl"
			-- 	end,
			-- },
			-- Messages
			{
				ft = "messages",
				title = "Messages",
				size = { height = 0.25 },
			},
			-- {
			-- 	ft = "log",
			-- 	title = "Log",
			-- 	size = { width = 0.25 },
			-- 	filter = function(buf)
			-- 		return vim.bo[buf].filetype == "log" and not vim.api.nvim_buf_get_name(buf):match("flutter")
			-- 	end,
			-- },
		},
	},
	init = function()
		vim.opt.laststatus = 3
		vim.opt.splitkeep = "screen"
	end,
}

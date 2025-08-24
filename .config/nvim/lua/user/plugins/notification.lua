return {
	"folke/noice.nvim",
	-- event = "VeryLazy",
  event = "UIEnter",
	opts = {
		routes = {
			-- Skip AutoSave messages
			{
				filter = {
					event = "msg_show",
					kind = "echomsg",
					find = "AutoSave:",
				},
				opts = { skip = true },
			},
			-- Skip written messages
			{
				filter = {
					event = "msg_show",
					kind = "",
					find = "written",
				},
				opts = { skip = true },
			},
			-- Skip showcmd messages
			{
				filter = {
					event = "msg_showcmd",
				},
				opts = { skip = true },
			},
		},
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
		},
		presets = {
			bottom_search = true,
			command_palette = true,
			long_message_to_split = true,
			inc_rename = false,
			lsp_doc_border = false,
		},
	},
	dependencies = {
		"MunifTanjim/nui.nvim",
		{
			"rcarriga/nvim-notify",
			opts = {
				stages = "fade_in_slide_out",
				background_colour = "#000000",
				timeout = 3000,
				render = "compact",
				top_down = false,

				-- Override default positioning
				on_open = function(win)
					local buf = vim.api.nvim_win_get_buf(win)
					vim.api.nvim_buf_set_option(buf, "filetype", "notify")
					local config = vim.api.nvim_win_get_config(win)

					-- Force bottom right position
					config.anchor = "SE"
					config.col = vim.o.columns - 2
					config.row = vim.o.lines - vim.o.cmdheight - 2

					vim.api.nvim_win_set_config(win, config)
				end,

				max_width = function()
					return math.floor(vim.o.columns * 0.25)
				end,
				max_height = function()
					return math.floor(vim.o.lines * 0.75)
				end,
			},
		},
	},
	keys = {
		{ "<leader>um", "<cmd>NoiceAll<cr>", desc = "Show messages" },
	},
}

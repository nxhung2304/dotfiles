return {
	"yetone/avante.nvim",
	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	-- ⚠️ must add this setting! ! !
	build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
		or "make",
	event = "VeryLazy",
	version = false, -- Never set this value to "*"! Never!
	---@module 'avante'
	---@type avante.Config
	opts = {
		behaviour = {
			auto_suggestions = true, -- Enable auto suggestions
		},
		-- suggestion = {
		-- 	debounce = 300, -- Delay trước khi trigger suggestion
		-- 	throttle = 600, -- Giới hạn tần suất request
		-- 	accept = "<M-l>", -- Accept suggestion
		-- 	next = "<M-]>", -- Next suggestion
		-- 	prev = "<M-[>", -- Previous suggestion
		-- 	dismiss = "<C-]>", -- Dismiss suggestion
		-- },
		provider = "gemini",
		prompt_logger = {
			enabled = false,
		},
		debug = false,

		windows = {
			position = "right", -- "right" | "left" | "top" | "bottom"
			wrap = true,
			width = 30, -- % width
			border = "rounded",
			sidebar_header = {
				enabled = true,
				align = "center",
				rounded = true,
			},
			input = {
				border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
				height = 8,
			},
			edit = {
				border = "rounded",
				start_insert = true,
			},
			ask = {
				floating = false,
				start_insert = true,
				border = "rounded",
			},
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		-- --- The below dependencies are optional,
		-- "echasnovski/mini.pick", -- for file_selector provider mini.pick
		-- "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
		-- "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
		-- "ibhagwan/fzf-lua", -- for file_selector provider fzf
		-- "stevearc/dressing.nvim", -- for input provider dressing
		-- "folke/snacks.nvim", -- for input provider snacks
		-- "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		-- "zbirenbaum/copilot.lua", -- for providers='copilot'
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					-- required for Windows users
					use_absolute_path = true,
				},
			},
		},
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}

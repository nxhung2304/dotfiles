local utils = require("user.core.utils")
local fluter_utils = require("user.plugins.flutter.flutter_utils")

return {
	"akinsho/flutter-tools.nvim",
	ft = {
		"dart",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"stevearc/dressing.nvim",
	},
	config = function()
		require("flutter-tools").setup({
			flutter_path = vim.fn.system("which flutter"):gsub("\n", ""),

			root_patterns = { ".git", "pubspec.yaml", ".fvm" },

			decorations = {
				statusline = {
					app_version = true,
					device = true,
					project_config = false,
				},
			},

			debugger = {
				enabled = false,
				exception_breakpoints = {},
				evaluate_to_string_in_debug_views = true,
			},

			flutter_lookup_cmd = nil,
			fvm = true,

			widget_guides = {
				enabled = false,
			},

			closing_tags = {
				highlight = "ErrorMsg",
				prefix = "</",
				priority = 10,
				enabled = true,
			},

			dev_log = {
				enabled = true,
				filter = nil,
				notify_errors = true,
				-- open_cmd = "30vnew",
				open_cmd = "tabnew | term",
				focus_on_open = true,
			},

			default_run_args = { flutter = "--no-sound-null-safety" },

			dev_tools = {
				autostart = false,
				auto_open_browser = false,
			},

			outline = {
				open_cmd = "30vnew",
				auto_open = false,
			},

			lsp = {
				color = {
					enabled = false,
					background = false,
					background_color = nil,
					foreground = false,
					virtual_text = true,
					virtual_text_str = "■",
				},

				flags = {
					debounce_text_changes = 150,
				},

				on_attach = utils.lsp_on_attach,

				settings = {
					showTodos = true,
					completeFunctionCalls = true,
					analysisExcludedFolders = { "<path-to-flutter-sdk-packages>" },
					renameFilesWithClasses = "prompt",
					enableSnippets = true,
					updateImportsOnRename = true,
				},
			},
		})

		require("flutter-tools").setup_project({
			{
				name = "iPhone 16 - Dev", -- an arbitrary name that you provide so you can recognise this config
				-- flavor = "DevFlavor", -- your flavour
				-- target = "lib/main.dart", -- your target
				device = "00008140-000C6D961447001C", -- the device ID, which you can get by running `flutter devices`
				-- dart_define = {
				-- 	API_URL = "https://dev.example.com/api",
				-- 	IS_DEV = true,
				-- },
				-- pre_run_callback = nil, -- optional callback to run before the configuration
				-- -- exposes a table containing name, target, flavor and device in the arguments
				-- dart_define_from_file = "config.json", -- the path to a JSON configuration file
			},
			{
				name = "Web - Dev",
				device = "chrome",
				-- flavor = "WebApp",
				web_port = "4000",
				additional_args = { "--wasm" },
			},
			{
				name = "Profile",
				flutter_mode = "profile", -- possible values: `debug`, `profile` or `release`, defaults to `debug`
			},
		})
	end,

	keys = {
		{
			"<leader>Fs",
			"FlutterRun",
			desc = "Flutter Run",
		},
		{
			"<leader>Fq",
			function()
				vim.cmd("FlutterQuit")
			end,
			desc = "Stop Debug & Quit Flutter",
		},

		{
			"<leader>Fr",
			"FlutterReload",
			desc = "Flutter Hot Reload (Debug)",
		},
		{
			"<leader>FR",
			"FlutterRestart",
			desc = "Flutter Hot Restart (Debug)",
		},
		{
			"<leader>Fd",
			"FlutterDevices",
			desc = "Select devices",
		},

		-- Log management
		{ "<leader>Fl", "<cmd>FlutterLogToggle<cr>", desc = "Flutter Log Toggle" },
		{ "<leader>FC", "<cmd>FlutterLogClear<cr>", desc = "Flutter Log Clear" },

		{
			"<leader>Ft",
			function()
				fluter_utils.create_or_open_test_file()
			end,
			desc = "Create/Open Test File",
		},
	},
}

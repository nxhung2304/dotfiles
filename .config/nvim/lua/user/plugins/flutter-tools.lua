local utils = require("user.core.utils")

return {
	"akinsho/flutter-tools.nvim",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"stevearc/dressing.nvim",
	},
	config = function()
		require("flutter-tools").setup({
			flutter_path = vim.fn.system("which flutter"):gsub("\n", ""),

			root_patterns = { ".git", "pubspec.yaml" },

			decorations = {
				statusline = {
					-- set to true to be able use the 'flutter_tools_decorations.app_version' in your statusline
					-- this will show the current version of the flutter app from the pubspec.yaml file
					app_version = true,
					-- set to true to be able use the 'flutter_tools_decorations.device' in your statusline
					-- this will show the currently running device if an application was started with a specific
					-- device
					device = true,
					-- set to true to be able use the 'flutter_tools_decorations.project_config' in your statusline
					-- this will show the currently selected project configuration
					project_config = false,
				},
			},

			debugger = { -- integrate with nvim dap + install dart code debugger
				enabled = false,
				-- if empty dap will not stop on any exceptions, otherwise it will stop on those specified
				-- see |:help dap.set_exception_breakpoints()| for more info
				exception_breakpoints = {},
				-- Whether to call toString() on objects in debug views like hovers and the
				-- variables list.
				-- Invoking toString() has a performance cost and may introduce side-effects,
				-- although users may expected this functionality. null is treated like false.
				evaluate_to_string_in_debug_views = true,
				-- You can use the `debugger.register_configurations` to register custom runner configuration (for example for different targets or flavor). Plugin automatically registers the default configuration, but you can override it or add new ones.
				-- register_configurations = function(paths)
				--   require("dap").configurations.dart = {
				--     -- your custom configuration
				--   }
				-- end,
			},

			flutter_lookup_cmd = nil, -- example "dirname $(which flutter)" or "asdf where flutter"
			fvm = false, -- takes priority over path, uses <workspace>/.fvm/flutter_sdk if enabled
			default_run_args = nil, -- Default options for run command (i.e `{ flutter = "--no-version-check" }`). Configured separately for `dart run` and `flutter run`.
			widget_guides = {
				enabled = false,
			},
			closing_tags = {
				highlight = "ErrorMsg", -- highlight for the closing tag
				prefix = "</", -- character to use for close tag e.g. > Widget
				priority = 10, -- priority of virtual text in current line
				-- consider to configure this when there is a possibility of multiple virtual text items in one line
				-- see `priority` option in |:help nvim_buf_set_extmark| for more info
				enabled = true, -- set to false to disable
			},

			dev_log = {
				enabled = true,
				filter = nil, -- optional callback to filter the log
				-- takes a log_line as string argument; returns a boolean or nil;
				-- the log_line is only added to the output if the function returns true
				notify_errors = true, -- if there is an error whilst running then notify the user
				open_cmd = "30vnew",
				focus_on_open = true, -- focus on the newly opened log window
			},

			dev_tools = {
				autostart = false, -- autostart devtools server if not detected
				auto_open_browser = false, -- Automatically opens devtools in the browser
			},

			outline = {
				open_cmd = "30vnew", -- command to use to open the outline buffer
				auto_open = false, -- if true this will open the outline automatically when it is first populated
			},

			lsp = {
				-- color = {
				-- 	enabled = true,
				-- 	background = false,
				-- 	virtual_text = false,
				-- },
				color = { -- show the derived colours for dart variables
					enabled = false, -- whether or not to highlight color variables at all, only supported on flutter >= 2.10
					background = false, -- highlight the background
					background_color = nil, -- required, when background is transparent (i.e. background_color = { r = 19, g = 17, b = 24},)
					foreground = false, -- highlight the foreground
					virtual_text = true, -- show the highlight using virtual text
					virtual_text_str = "■", -- the virtual text character to highlight
				},

				flags = {
					debounce_text_changes = 150,
				},

				on_attach = utils.lsp_on_attach,

				settings = {
					showTodos = true,
					completeFunctionCalls = true,
					analysisExcludedFolders = { "<path-to-flutter-sdk-packages>" },
					renameFilesWithClasses = "prompt", -- "always"
					enableSnippets = true,
					updateImportsOnRename = true, -- Whether to update imports and other directives when files are renamed. Required for `FlutterRename` command.
				},
			},
		})
	end,
	keys = {
		-- Run & Debug
		{
			"<leader>Fs",
			function()
				vim.cmd("FlutterRun")
				vim.cmd("FlutterLogToggle")
			end,
			desc = "Flutter Run & Open Log",
		},
		{ "<leader>Fd", "<cmd>FlutterDebug<cr>", desc = "Flutter Debug" },
		{ "<leader>Fq", "<cmd>FlutterQuit<cr>", desc = "Flutter Quit" },

		-- Hot reload (quan trọng nhất!)
		{ "<leader>Fr", "<cmd>FlutterReload<cr>", desc = "Flutter Hot Reload" },
		{ "<leader>FR", "<cmd>FlutterRestart<cr>", desc = "Flutter Hot Restart" },

		-- Device management
		{ "<leader>FD", "<cmd>FlutterDevices<cr>", desc = "Flutter Devices" },
		{ "<leader>FE", "<cmd>FlutterEmulators<cr>", desc = "Flutter Emulators" },

		-- Log management
		{ "<leader>Fl", "<cmd>FlutterLogToggle<cr>", desc = "Flutter Log Toggle" },
		{ "<leader>FC", "<cmd>FlutterLogClear<cr>", desc = "Flutter Log Clear" },

		-- LSP & Development
		{ "<leader>FL", "<cmd>FlutterLspRestart<cr>", desc = "Flutter LSP Restart" },
		{ "<leader>FA", "<cmd>FlutterReanalyze<cr>", desc = "Flutter Reanalyze" },
		{ "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", desc = "Flutter Outline Toggle" },

		-- DevTools
		{ "<leader>Ft", "<cmd>FlutterDevTools<cr>", desc = "Flutter DevTools" },
		{ "<leader>Fp", "<cmd>FlutterCopyProfilerUrl<cr>", desc = "Copy Profiler URL" },
	},
}

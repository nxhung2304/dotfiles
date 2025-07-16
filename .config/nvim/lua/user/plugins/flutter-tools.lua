local utils = require("user.core.utils")

return {
	"akinsho/flutter-tools.nvim",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"stevearc/dressing.nvim",
		"mfussenegger/nvim-dap", -- Thêm dependency nvim-dap
	},
	config = function()
		require("flutter-tools").setup({
			flutter_path = vim.fn.system("which flutter"):gsub("\n", ""),

			root_patterns = { ".git", "pubspec.yaml" },

			decorations = {
				statusline = {
					app_version = true,
					device = true,
					project_config = false,
				},
			},

			debugger = {
				enabled = true,
				run_via_dap = true, -- QUAN TRỌNG: Chạy debug qua nvim-dap
				exception_breakpoints = { "uncaught", "raised" }, -- Dừng tại exception
				evaluate_to_string_in_debug_views = true,
				register_configurations = function(paths)
					local dap = require("dap")

					-- Override configurations để tương tác với nvim-dap
					dap.configurations.dart = {
						-- Configuration cho Flutter Debug (sử dụng adapter dart)
						{
							type = "dart",
							request = "launch",
							name = "Launch Flutter (Debug)",
							dartSdkPath = paths.dart_sdk,
							flutterSdkPath = paths.flutter_sdk,
							program = "${workspaceFolder}/lib/main.dart",
							cwd = "${workspaceFolder}",
							console = "terminal",
							args = {},
							vmArgs = {},
							flutterMode = "debug",
						},
						-- Configuration cho Flutter Profile mode
						{
							type = "dart",
							request = "launch",
							name = "Launch Flutter (Profile)",
							dartSdkPath = paths.dart_sdk,
							flutterSdkPath = paths.flutter_sdk,
							program = "${workspaceFolder}/lib/main.dart",
							cwd = "${workspaceFolder}",
							console = "terminal",
							args = { "--profile" },
							vmArgs = {},
							flutterMode = "profile",
						},
						-- Configuration cho Flutter Release mode
						{
							type = "dart",
							request = "launch",
							name = "Launch Flutter (Release)",
							dartSdkPath = paths.dart_sdk,
							flutterSdkPath = paths.flutter_sdk,
							program = "${workspaceFolder}/lib/main.dart",
							cwd = "${workspaceFolder}",
							console = "terminal",
							args = { "--release" },
							vmArgs = {},
							flutterMode = "release",
						},
						-- Configuration cho file Dart đơn lẻ
						{
							type = "dart",
							request = "launch",
							name = "Launch Dart File",
							program = "${file}",
							cwd = "${fileDirname}",
							console = "terminal",
							args = {},
							vmArgs = {},
						},
					}
				end,
			},

			flutter_lookup_cmd = nil,
			fvm = false,
			default_run_args = nil,

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
				open_cmd = "45vnew",
				focus_on_open = true,
			},

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

		-- Tạo function để smart debug
		local function flutter_smart_debug()
			-- Kiểm tra filetype hiện tại
			local current_filetype = vim.bo.filetype

			-- Nếu không phải file Dart, tìm file Dart gần nhất
			if current_filetype ~= "dart" then
				-- Tìm file main.dart hoặc file .dart trong project
				local workspace_folder = vim.fn.getcwd()
				local main_dart = workspace_folder .. "/lib/main.dart"

				if vim.fn.filereadable(main_dart) == 1 then
					-- Mở main.dart và focus vào đó
					vim.cmd("edit " .. main_dart)
					print("Switched to main.dart for debugging")
				else
					print("Error: No Dart file found. Please open a .dart file first.")
					return
				end
			end

			local workspace_folder = vim.fn.getcwd()
			local pubspec_path = workspace_folder .. "/pubspec.yaml"
			local has_pubspec = vim.fn.filereadable(pubspec_path) == 1

			local dap = require("dap")

			if has_pubspec then
				-- Flutter project - tự động chọn "Launch Flutter (Debug)"
				print("Starting Flutter debug session...")

				-- Tìm configuration "Launch Flutter (Debug)"
				local configs = dap.configurations.dart or {}
				local flutter_config = nil

				for _, config in ipairs(configs) do
					if config.name == "Launch Flutter (Debug)" then
						flutter_config = config
						break
					end
				end

				if flutter_config then
					dap.run(flutter_config)
				end
				vim.cmd("FlutterRun")
				vim.cmd("FlutterLogToggle")
			else
				-- File Dart đơn lẻ - tự động chọn "Launch Dart File"
				print("Starting Dart file debug...")

				local configs = dap.configurations.dart or {}
				local dart_config = nil

				for _, config in ipairs(configs) do
					if config.name == "Launch Dart File" then
						dart_config = config
						break
					end
				end

				if dart_config then
					dap.run(dart_config)
				else
					-- Fallback: dùng dap.continue()
					dap.continue()
				end
			end
		end

		-- Function để hot reload thông qua DAP
		local function smart_reload()
			-- Kiểm tra filetype
			if vim.bo.filetype ~= "dart" then
				print("Please switch to a Dart file first")
				return
			end

			local dap = require("dap")
			local session = dap.session()

			if session then
				-- Dùng FlutterReload command
				vim.cmd("FlutterReload")
				print("Hot reloading...")
			else
				-- Không có debug session, thử chạy flutter run
				print("No debug session active. Starting Flutter...")
				vim.cmd("FlutterRun")
			end
		end

		-- Function để hot restart thông qua DAP
		local function smart_restart()
			-- Kiểm tra filetype
			if vim.bo.filetype ~= "dart" then
				print("Please switch to a Dart file first")
				return
			end

			local session = require("dap").session()
			if session then
				vim.cmd("FlutterRestart")
			else
				print("No debug session active")
			end
		end

		-- Expose functions globally
		_G.flutter_smart_debug = flutter_smart_debug
		_G.smart_reload = smart_reload
		_G.smart_restart = smart_restart

		-- Function để debug an toàn
		local function safe_dap_continue()
			local current_filetype = vim.bo.filetype

			if current_filetype == "dart" then
				local workspace_folder = vim.fn.getcwd()
				local pubspec_path = workspace_folder .. "/pubspec.yaml"
				local has_pubspec = vim.fn.filereadable(pubspec_path) == 1

				local dap = require("dap")
				local configs = dap.configurations.dart or {}

				if has_pubspec then
					-- Tự động chọn Flutter config
					for _, config in ipairs(configs) do
						if config.name == "Launch Flutter (Debug)" then
							dap.run(config)
							return
						end
					end
					-- Fallback
					dap.continue()
				else
					-- Tự động chọn Dart file config
					for _, config in ipairs(configs) do
						if config.name == "Launch Dart File" then
							dap.run(config)
							return
						end
					end
					-- Fallback
					dap.continue()
				end
			else
				print("Error: Not in a Dart file. Current filetype: " .. current_filetype)
				print("Please open a .dart file first")
			end
		end

		-- Function để kiểm tra DAP configs
		local function debug_dap_configs()
			local dap = require("dap")
			print("=== DAP Adapters ===")
			for name, adapter in pairs(dap.adapters) do
				print("Adapter: " .. name)
			end

			print("\n=== DAP Configurations ===")
			if dap.configurations.dart then
				for i, config in ipairs(dap.configurations.dart) do
					print(i .. ". " .. config.name .. " (type: " .. config.type .. ")")
				end
			else
				print("No dart configurations found")
			end
		end

		_G.debug_dap_configs = debug_dap_configs
	end,

	keys = {
		-- Debug commands - tự động chọn configuration
		{
			"<leader>Fs",
			function()
				_G.flutter_smart_debug()
			end,
			desc = "Flutter Smart Debug (Auto-select)",
		},
		{
			"<leader>Fd",
			function()
				_G.safe_dap_continue()
			end,
			desc = "DAP Continue/Start Debug (Auto-select)",
		},
		-- Debug với lựa chọn manual
		{
			"<leader>Fm",
			function()
				if vim.bo.filetype == "dart" then
					require("dap").continue() -- Sẽ hiện Telescope prompt
				else
					print("Please open a Dart file first")
				end
			end,
			desc = "Debug with Manual Selection",
		},
		-- Debug Flutter trực tiếp
		{
			"<leader>Ff",
			function()
				if vim.bo.filetype == "dart" then
					local dap = require("dap")
					local configs = dap.configurations.dart or {}
					for _, config in ipairs(configs) do
						if config.name == "Launch Flutter (Debug)" then
							print("Found Flutter config, starting debug...")
							dap.run(config)
							return
						end
					end
					print("Flutter debug config not found")
					_G.debug_dap_configs() -- Debug info
				else
					print("Please open a Dart file first")
				end
			end,
			desc = "Launch Flutter Debug",
		},
		-- Debug info
		{
			"<leader>Fi",
			function()
				_G.debug_dap_configs()
			end,
			desc = "Debug DAP Configs Info",
		},
		-- Debug Dart file trực tiếp
		{
			"<leader>Fa",
			function()
				if vim.bo.filetype == "dart" then
					local dap = require("dap")
					local configs = dap.configurations.dart or {}
					for _, config in ipairs(configs) do
						if config.name == "Launch Dart File" then
							dap.run(config)
							return
						end
					end
					print("Dart file debug config not found")
				else
					print("Please open a Dart file first")
				end
			end,
			desc = "Launch Dart File Debug",
		},
		{
			"<leader>Fq",
			function()
				require("dap").terminate()
				vim.cmd("FlutterQuit")
			end,
			desc = "Stop Debug & Quit Flutter",
		},

		-- Hot reload/restart thông qua debug session
		{
			"<leader>Fr",
			function()
				_G.smart_reload()
			end,
			desc = "Flutter Hot Reload (Debug)",
		},
		{
			"<leader>FR",
			function()
				_G.smart_restart()
			end,
			desc = "Flutter Hot Restart (Debug)",
		},

		-- -- Debug controls - nvim-dap keymaps
		-- {
		-- 	"<leader>Fb",
		-- 	function()
		-- 		require("dap").toggle_breakpoint()
		-- 	end,
		-- 	desc = "Toggle Breakpoint",
		-- },
		-- {
		-- 	"<leader>FB",
		-- 	function()
		-- 		require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
		-- 	end,
		-- 	desc = "Conditional Breakpoint",
		-- },
		-- {
		-- 	"<leader>Fn",
		-- 	function()
		-- 		require("dap").step_over()
		-- 	end,
		-- 	desc = "Step Over",
		-- },
		-- {
		-- 	"<leader>Fi",
		-- 	function()
		-- 		require("dap").step_into()
		-- 	end,
		-- 	desc = "Step Into",
		-- },
		-- {
		-- 	"<leader>Fo",
		-- 	function()
		-- 		require("dap").step_out()
		-- 	end,
		-- 	desc = "Step Out",
		-- },
		-- {
		-- 	"<leader>Fu",
		-- 	function()
		-- 		require("dapui").toggle()
		-- 	end,
		-- 	desc = "Toggle Debug UI",
		-- },
		-- {
		-- 	"<leader>Fe",
		-- 	function()
		-- 		require("dapui").eval()
		-- 	end,
		-- 	desc = "Evaluate Expression",
		-- },

		-- Device management
		{ "<leader>FD", "<cmd>FlutterDevices<cr>", desc = "Flutter Devices" },
		{ "<leader>FE", "<cmd>FlutterEmulators<cr>", desc = "Flutter Emulators" },

		-- Log management
		{ "<leader>Fl", "<cmd>FlutterLogToggle<cr>", desc = "Flutter Log Toggle" },
		{ "<leader>FC", "<cmd>FlutterLogClear<cr>", desc = "Flutter Log Clear" },

		-- LSP & Development
		{ "<leader>FL", "<cmd>FlutterLspRestart<cr>", desc = "Flutter LSP Restart" },
		{ "<leader>FA", "<cmd>FlutterReanalyze<cr>", desc = "Flutter Reanalyze" },
		{ "<leader>FO", "<cmd>FlutterOutlineToggle<cr>", desc = "Flutter Outline Toggle" },

		-- DevTools
		{ "<leader>Ft", "<cmd>FlutterDevTools<cr>", desc = "Flutter DevTools" },
		{ "<leader>Fp", "<cmd>FlutterCopyProfilerUrl<cr>", desc = "Copy Profiler URL" },
	},
}

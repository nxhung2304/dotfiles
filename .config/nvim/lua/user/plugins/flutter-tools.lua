local utils = require("user.core.utils")

return {
	"akinsho/flutter-tools.nvim",
	-- lazy = false,
	ft = {
		"dart",
	},
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
				-- exception_breakpoints = { "uncaught", "raised" }, -- Dừng tại exception
				exception_breakpoints = {},
				evaluate_to_string_in_debug_views = true,
				force_setup = true,
				register_configurations = function(paths)
					local dap = require("dap")

					dap.adapters.dart = {
						type = "executable",
						command = paths.flutter_sdk .. "/bin/flutter",
						args = { "debug_adapter" },
						options = {
							detached = false,
						},
					}

					if not dap.configurations.dart then
						dap.configurations.dart = {}
					end

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
							args = { "--dart-define=FLAVOR=development" },
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
							args = { "--profile", "--dart-define=FLAVOR=development" },
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
							args = { "--release", "--dart-define=FLAVOR=production" },
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

			-- if has_pubspec then
			-- 	-- Flutter project - tự động chọn "Launch Flutter (Debug)"
			-- 	print("Starting Flutter debug session...")
			--
			-- 	-- Tìm configuration "Launch Flutter (Debug)"
			-- 	local configs = dap.configurations.dart or {}
			-- 	local flutter_config = nil
			--
			-- 	for _, config in ipairs(configs) do
			-- 		if config.name == "Launch Flutter (Debug)" then
			-- 			flutter_config = config
			-- 			break
			-- 		end
			-- 	end
			--
			-- 	if flutter_config then
			-- 		dap.run(flutter_config)
			-- 	end
			-- 	vim.cmd("FlutterRun")
			-- 	vim.cmd("FlutterLogToggle")
			-- else
			-- 	-- File Dart đơn lẻ - tự động chọn "Launch Dart File"
			-- 	print("Starting Dart file debug...")
			--
			-- 	local configs = dap.configurations.dart or {}
			-- 	local dart_config = nil
			--
			-- 	for _, config in ipairs(configs) do
			-- 		if config.name == "Launch Dart File" then
			-- 			dart_config = config
			-- 			break
			-- 		end
			-- 	end
			--
			-- 	if dart_config then
			-- 		dap.run(dart_config)
			-- 	else
			-- 		-- Fallback: dùng dap.continue()
			-- 		dap.continue()
			-- 	end
			-- end

			if has_pubspec then
				vim.cmd("FlutterRun") -- CHỈ dùng FlutterRun
			else
				require("dap").continue()
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
		-- Debug với lựa chọn manual
		-- Debug Dart file trực tiếp
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

		-- Log management
		{ "<leader>Fl", "<cmd>FlutterLogToggle<cr>", desc = "Flutter Log Toggle" },
		{ "<leader>FC", "<cmd>FlutterLogClear<cr>", desc = "Flutter Log Clear" },

		-- LSP & Development
		{ "<leader>FL", "<cmd>FlutterLspRestart<cr>", desc = "Flutter LSP Restart" },
		{ "<leader>FA", "<cmd>FlutterReanalyze<cr>", desc = "Flutter Reanalyze" },
		{ "<leader>FO", "<cmd>FlutterOutlineToggle<cr>", desc = "Flutter Outline Toggle" },

		{
			"<leader>Ft",
			function()
				local function create_or_open_test_file()
					local current_file = vim.fn.expand("%:p")
					local current_filetype = vim.bo.filetype

					-- Kiểm tra nếu không phải file Dart
					if current_filetype ~= "dart" then
						print("Error: Please open a Dart file first")
						return
					end

					local workspace_folder = vim.fn.getcwd()
					local relative_path = vim.fn.fnamemodify(current_file, ":.")
					local file_name = vim.fn.fnamemodify(current_file, ":t:r")

					-- Kiểm tra nếu đang ở file test
					if file_name:match("_test$") then
						print("Already in a test file: " .. relative_path)
						return
					end

					-- Kiểm tra nếu file trong thư mục test/
					if relative_path:match("^test/") then
						print("Already in test directory: " .. relative_path)
						return
					end

					local class_name = file_name:gsub("^%l", string.upper) -- Capitalize first letter

					-- Tạo đường dẫn test file với cấu trúc y hệt
					local test_file_path

					if relative_path:match("^lib/") then
						-- File trong lib/ -> giữ nguyên cấu trúc trong test/
						-- lib/core/services/network_connectivity.dart -> test/core/services/network_connectivity_test.dart
						local lib_path = relative_path:gsub("^lib/", "") -- bỏ lib/ prefix
						local dir_path = lib_path:gsub("/[^/]*$", "") -- lấy thư mục (core/services)
						local test_filename = file_name .. "_test.dart"

						if dir_path == lib_path then
							-- File ở root lib/ (lib/main.dart)
							test_file_path = workspace_folder .. "/test/" .. test_filename
						else
							-- File trong subfolder (lib/core/services/file.dart)
							test_file_path = workspace_folder .. "/test/" .. dir_path .. "/" .. test_filename
						end
					else
						-- File không trong lib/ -> tạo test trong test/
						test_file_path = workspace_folder .. "/test/" .. file_name .. "_test.dart"
					end

					-- Kiểm tra file test đã tồn tại chưa
					if vim.fn.filereadable(test_file_path) == 1 then
						-- File test đã tồn tại, mở nó
						vim.cmd("edit " .. test_file_path)
						print("Opened existing test file: " .. vim.fn.fnamemodify(test_file_path, ":."))
					else
						-- Tính toán relative path cho import helper
						local test_relative = test_file_path:gsub(workspace_folder .. "/", "")
						local depth = select(2, test_relative:gsub("/", "")) - 1 -- đếm số thư mục con từ root
						local helper_path = string.rep("../", depth) .. "helpers/test_helper.dart"

						-- Tạo thư mục nếu chưa có
						local test_dir = vim.fn.fnamemodify(test_file_path, ":h")
						vim.fn.mkdir(test_dir, "p")

						-- Template test file với import path động
						local template = string.format(
							[[import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {

  });
  tearDownAll(() {
    TestHelper.tearDownTestEnvironment();
  });
  group('%s Test', () {
    

  });
}]],
							helper_path,
							class_name
						)

						-- Tạo và mở file test
						local file = io.open(test_file_path, "w")
						if file then
							file:write(template)
							file:close()
							vim.cmd("edit " .. test_file_path)
							print("Created new test file: " .. vim.fn.fnamemodify(test_file_path, ":."))

							-- Di chuyển cursor đến vị trí thích hợp (trong group)
							vim.schedule(function()
								vim.fn.search("group.*Test.*{")
								vim.cmd("normal! o")
								vim.cmd("startinsert")
							end)
						else
							print("Error: Could not create test file")
						end
					end
				end

				create_or_open_test_file()
			end,
			desc = "Create/Open Test File",
		},
	},
}

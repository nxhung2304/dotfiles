local utils = require("user.core.utils")

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
				enabled = true,
				-- exception_breakpoints = { "uncaught", "raised" }, -- Dừng tại exception
				exception_breakpoints = {},
				evaluate_to_string_in_debug_views = true,
				-- force_setup = true,
			},

			flutter_lookup_cmd = nil,
			fvm = true,
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

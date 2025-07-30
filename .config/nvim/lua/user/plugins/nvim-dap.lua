return {
	"mfussenegger/nvim-dap",
	dependencies = {
		{
			"rcarriga/nvim-dap-ui",
			dependencies = { "mfussenegger/nvim-dap" },
			config = function()
				require("dapui").setup({
					expand_lines = true,
					icons = { expanded = "", collapsed = "", circular = "" },
					mappings = {
						expand = { "<CR>", "<2-LeftMouse>" },
						open = "o",
						remove = "d",
						edit = "e",
						repl = "r",
						toggle = "t",
					},
					layouts = {
						{
							elements = {
								{ id = "scopes", size = 0.5 },
								{ id = "breakpoints", size = 0.5 },
								-- { id = "stacks", size = 0.25 },
								-- { id = "watches", size = 0.25 },
							},
							size = 40,
							position = "left",
						},
						{
							elements = {
								{ id = "repl", size = 0.5 },
								-- { id = "console", size = 0.5 },
							},
							size = 0.25,
							position = "bottom",
						},
					},
					floating = {
						max_height = nil,
						max_width = nil,
						border = "single",
						mappings = {
							close = { "q", "<Esc>" },
						},
					},
					windows = { indent = 1 },
					render = {
						max_type_length = nil,
						max_value_lines = 100,
					},
				})
			end,
		},
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
	},
	config = function()
		local dap = require("dap")

		-- dap.adapters.dart = {
		-- 	type = "executable",
		-- 	command = "flutter",
		-- 	args = { "debug_adapter" },
		-- 	options = {
		-- 		detached = false,
		-- 	},
		-- }

		-- Cấu hình cho Dart/Flutter debugging
		-- dap.configurations.dart = {
		-- 	-- Configuration cho file Dart đơn lẻ
		-- 	{
		-- 		type = "dart",
		-- 		request = "launch",
		-- 		name = "Launch Dart File",
		-- 		program = "${file}",
		-- 		cwd = "${fileDirname}",
		-- 		console = "terminal",
		-- 		args = {},
		-- 	},
		-- 	-- -- Configuration cho Flutter project (sẽ được override bởi flutter-tools)
		-- 	-- {
		-- 	-- 	type = "dart",
		-- 	-- 	request = "launch",
		-- 	-- 	name = "Launch Flutter (Debug)",
		-- 	-- 	program = "${workspaceFolder}/lib/main.dart",
		-- 	-- 	cwd = "${workspaceFolder}",
		-- 	-- 	console = "terminal",
		-- 	-- 	args = {},
		-- 	-- },
		-- }

		-- Input configurations
		dap.configurations.inputs = {
			deviceId = {
				type = "command",
				command = "flutter",
				args = { "devices", "--machine" },
			},
		}

		-- Function để tự động chọn configuration phù hợp
		local function smart_continue()
			local current_file = vim.fn.expand("%:p")
			local workspace_folder = vim.fn.getcwd()

			-- Kiểm tra có phải Flutter project không
			local pubspec_path = workspace_folder .. "/pubspec.yaml"
			local has_pubspec = vim.fn.filereadable(pubspec_path) == 1

			if has_pubspec and current_file:match("lib/main%.dart$") then
				-- Flutter project
				print("Detected Flutter project, using Flutter configuration")
				dap.continue()
			elseif current_file:match("%.dart$") then
				-- File Dart đơn lẻ
				print("Detected standalone Dart file")
				dap.continue()
			else
				print("Not a Dart file")
			end
		end

		-- Keymaps cho debugging
		local function set_keymap(mode, lhs, rhs, opts)
			vim.keymap.set(mode, lhs, rhs, opts or {})
		end

		-- Debug keymaps
		set_keymap("n", "<leader>dc", smart_continue, { desc = "Smart continue debugging" })
		set_keymap("n", "<leader>dn", function()
			dap.step_over()
		end, { desc = "Step over (next)" })
		set_keymap("n", "<leader>di", function()
			dap.step_into()
		end, { desc = "Step into" })
		set_keymap("n", "<leader>do", function()
			dap.step_out()
		end, { desc = "Step out" })
		set_keymap("n", "<leader>db", function()
			dap.toggle_breakpoint()
		end, { desc = "Toggle breakpoint" })
		set_keymap("n", "<leader>dB", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, { desc = "Set conditional breakpoint" })
		set_keymap("n", "<leader>dr", function()
			dap.repl.open()
		end, { desc = "Open REPL" })
		set_keymap("n", "<leader>dl", function()
			dap.run_last()
		end, { desc = "Run last" })
		set_keymap("n", "<leader>dt", function()
			dap.terminate()
		end, { desc = "Terminate debugging" })
		set_keymap("n", "<leader>ds", function()
			dap.session()
		end, { desc = "Debug session info" })

		-- DAP UI keymaps
		set_keymap("n", "<leader>du", function()
			require("dapui").toggle()
			local view = require("nvim-tree.view")
			if view.is_visible() then
				vim.cmd("NvimTreeClose")
			end
		end, { desc = "Toggle DAP UI" })
		set_keymap("n", "<leader>de", function()
			require("dapui").eval()
		end, { desc = "Evaluate expression" })
		set_keymap("v", "<leader>de", function()
			require("dapui").eval()
		end, { desc = "Evaluate selection" })

		local dapui = require("dapui")

		-- Tự động mở/đóng UI khi debug
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- Auto commands để setup file-specific configurations
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "dart",
			callback = function()
				local workspace_folder = vim.fn.getcwd()
				local pubspec_path = workspace_folder .. "/pubspec.yaml"
				local has_pubspec = vim.fn.filereadable(pubspec_path) == 1

				if not has_pubspec then
					-- Nếu không có pubspec.yaml, set working directory là thư mục chứa file
					local file_dir = vim.fn.expand("%:p:h")
					vim.api.nvim_buf_set_var(0, "dap_cwd", file_dir)
				end
			end,
		})
	end,
}

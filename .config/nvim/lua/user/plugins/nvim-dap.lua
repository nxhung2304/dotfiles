return {
	"mfussenegger/nvim-dap",
	lazy = true,
	keys = {
		{ "<leader>dc", desc = "Debug: Continue" },
		{ "<leader>di", desc = "Debug: Step Into" },
		{ "<leader>do", desc = "Debug: Step Over" },
		{ "<leader>dO", desc = "Debug: Step Out" },
		{ "<leader>db", desc = "Debug: Toggle Breakpoint" },
		{ "<leader>dB", desc = "Debug: Conditional Breakpoint" },
		{ "<leader>dr", desc = "Debug: Restart" },
		{ "<leader>dt", desc = "Debug: Terminate" },
		{ "<leader>du", desc = "Debug: Toggle UI" },
		{ "<leader>de", desc = "Debug: Evaluate", mode = { "n", "v" } },
		{ "<leader>df", desc = "Debug: Float Element" },
	},
	dependencies = {
		-- UI for nvim-dap
		"rcarriga/nvim-dap-ui",
		-- Virtual text support
		"theHamsta/nvim-dap-virtual-text",
		-- Mason integration for installing debug adapters
		"jay-babu/mason-nvim-dap.nvim",
		"nvim-neotest/nvim-nio",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		-- Setup mason-nvim-dap for automatic debug adapter installation
		require("mason-nvim-dap").setup({
			ensure_installed = {
				"node2",
				"chrome",
				"js",
			},
			automatic_installation = true,
		})

		-- Setup virtual text
		require("nvim-dap-virtual-text").setup({
			enabled = true,
			enabled_commands = true,
			highlight_changed_variables = true,
			highlight_new_as_changed = false,
			show_stop_reason = true,
			commented = false,
			only_first_definition = true,
			all_references = false,
			clear_on_continue = false,
			display_callback = function(variable, buf, stackframe, node, options)
				if options.virt_text_pos == "inline" then
					return " = " .. variable.value
				else
					return variable.name .. " = " .. variable.value
				end
			end,
			virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
			all_frames = false,
			virt_lines = false,
			virt_text_win_col = nil,
		})

		-- Setup dap-ui
		dapui.setup({
			icons = { expanded = "", collapsed = "", current_frame = "" },
			mappings = {
				expand = { "<CR>", "<2-LeftMouse>" },
				open = "o",
				remove = "d",
				edit = "e",
				repl = "r",
				toggle = "t",
			},
			element_mappings = {},
			expand_lines = vim.fn.has("nvim-0.7") == 1,
			layouts = {
				{
					elements = {
						{ id = "scopes", size = 0.25 },
						"breakpoints",
						"stacks",
						"watches",
					},
					size = 40,
					position = "left",
				},
				{
					elements = {
						"repl",
						"console",
					},
					size = 0.25,
					position = "bottom",
				},
			},
			controls = {
				enabled = true,
				element = "repl",
				icons = {
					pause = "",
					play = "",
					step_into = "",
					step_over = "",
					step_out = "",
					step_back = "",
					run_last = "",
					terminate = "",
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

		-- Automatically open/close dap-ui
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- Debug adapter configurations
		-- Node.js debugging
		dap.adapters.node2 = {
			type = "executable",
			command = "node",
			args = { vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
		}

		dap.configurations.javascript = {
			{
				name = "Launch",
				type = "node2",
				request = "launch",
				program = "${file}",
				cwd = vim.fn.getcwd(),
				sourceMaps = true,
				protocol = "inspector",
				console = "integratedTerminal",
			},
			{
				name = "Attach to process",
				type = "node2",
				request = "attach",
				processId = require("dap.utils").pick_process,
			},
		}

		dap.configurations.typescript = dap.configurations.javascript

		-- Signs
		vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
		vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
		vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
		vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticHint", linehl = "DapStoppedLine", numhl = "" })
		vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })

		-- Debug keymaps using which-key leader pattern
		local keymap = vim.keymap.set

		keymap("n", "<leader>dc", dap.continue, { desc = "Continue" })
		keymap("n", "<leader>di", dap.step_into, { desc = "Step Into" })
		keymap("n", "<leader>do", dap.step_over, { desc = "Step Over" })
		keymap("n", "<leader>dO", dap.step_out, { desc = "Step Out" })
		keymap("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
		keymap("n", "<leader>dB", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, { desc = "Conditional Breakpoint" })
		keymap("n", "<leader>dr", dap.restart, { desc = "Restart" })
		keymap("n", "<leader>dt", dap.terminate, { desc = "Terminate" })

		-- DAP UI keymaps
		keymap("n", "<leader>du", dapui.toggle, { desc = "Toggle UI" })
		keymap("n", "<leader>de", dapui.eval, { desc = "Evaluate" })
		keymap("v", "<leader>de", dapui.eval, { desc = "Evaluate Selection" })
		keymap("n", "<leader>df", dapui.float_element, { desc = "Float Element" })
	end,
}

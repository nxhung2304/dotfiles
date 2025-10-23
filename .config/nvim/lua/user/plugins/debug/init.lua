return {
	"igorlfs/nvim-dap-view",
	event = "VeryLazy", -- Lazy-load on VeryLazy event for global availability without immediate load
	dependencies = {
		"mfussenegger/nvim-dap", -- Core DAP
		"suketa/nvim-dap-ruby",
		{
			"mxsdev/nvim-dap-vscode-js",
			dependencies = {
				{
					"microsoft/vscode-js-debug",
					build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
				},
			},
			ft = { "typescript", "javascript", "vue" }, -- Lazy-load JS debugger on relevant filetypes
		},
	},
	opts = {
		winbar = {
			controls = {
				enabled = true,
			},
		},
	},
	config = function(_, opts)
		local dap = require("dap")
		local dapui = require("dap-view") -- nvim-dap-view alias

		dapui.setup(opts)

		-- Load language-specific configs
		require("user.plugins.debug.vuejs").config(dap)
		require("user.plugins.debug.ruby").config(dap)

		-- Debug keymaps (leader-based, no F-keys; always active after VeryLazy)
		-- These will lazy-trigger the plugin if not loaded yet
		local keymap = vim.keymap.set
    local base_opts = { noremap = true, silent = true }

		-- Breakpoints
		keymap("n", "<leader>db", function()
			dap.toggle_breakpoint()
		end, vim.tbl_extend("force", base_opts, { desc = "Toggle breakpoint" }))
		keymap("n", "<leader>dB", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, vim.tbl_extend("force", base_opts, { desc = "Set conditional breakpoint" }))

		-- Launch/Continue
		keymap("n", "<leader>dc", function()
			dap.continue()
		end, vim.tbl_extend("force", base_opts, { desc = "Continue debugging" }))
		keymap("n", "<leader>dr", function()
			dap.repl.open()
		end, vim.tbl_extend("force", base_opts, { desc = "Open REPL" }))

		-- Step actions
		keymap("n", "<leader>di", function()
			dap.step_into()
		end, vim.tbl_extend("force", base_opts, { desc = "Step into" }))
		keymap("n", "<leader>do", function()
			dap.step_over()
		end, vim.tbl_extend("force", base_opts, { desc = "Step over" }))
		keymap("n", "<leader>dO", function()
			dap.step_out()
		end, vim.tbl_extend("force", base_opts, { desc = "Step out" }))

		-- UI/Term
		keymap("n", "<leader>du", function()
			dapui.toggle()
		end, vim.tbl_extend("force", base_opts, { desc = "Toggle DAP UI" }))
		keymap("n", "<leader>dt", function()
			dapui.toggle("dapui_watches")
		end, vim.tbl_extend("force", base_opts, { desc = "Toggle watches" }))
		keymap("n", "<leader>dx", function()
			dapui.close()
		end, vim.tbl_extend("force", base_opts, { desc = "Close DAP UI" }))
		keymap("n", "<leader>dT", function()
			dapui.toggle("dapui_hover")
		end, vim.tbl_extend("force", base_opts, { desc = "Toggle hover" }))

		-- Terminate
		keymap("n", "<leader>dq", function()
			dap.terminate()
		end, vim.tbl_extend("force", base_opts, { desc = "Terminate debug session" }))

		-- DAP events for session-specific keymaps (always active during debug)
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end
	end,
}

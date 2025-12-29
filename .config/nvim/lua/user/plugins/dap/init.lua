return {
	"mfussenegger/nvim-dap",
	dependencies = {
		{
			"igorlfs/nvim-dap-view",
			opts = {
				-- Config theo schema chính xác: winbar cho mappings/sections, windows cho layout
				auto_toggle = true, -- Tự mở views khi DAP session start (thay auto_open)
				follow_tab = false, -- Không reopen khi switch tab (tùy chọn)
				windows = { -- Layout cho debug windows (thay layout)
					height = 0.25, -- Chiều cao views (% màn hình)
					position = "below", -- Vị trí: "below" (dưới editor), "right", "top", "left"
					terminal = {
						width = 0.5, -- Chiều rộng terminal (%)
						position = "left",
						start_hidden = true, -- Ẩn terminal lúc start (Flutter log riêng)
						hide = { "dart" }, -- Luôn ẩn terminal cho Dart/Flutter (dùng FlutterLogToggle thay)
					},
				},
				winbar = { -- Mappings và sections cho winbar (thay top-level mappings)
					show = true,
					sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "console" },
					default_section = "scopes", -- Default view: scopes (hữu ích cho Flutter vars)
					base_sections = {
						breakpoints = { keymap = "B", label = "Breakpoints [B]", short_label = "BP [B]" },
						scopes = { keymap = "S", label = "Scopes [S]", short_label = "Scopes [S]" },
						exceptions = { keymap = "E", label = "Exceptions [E]", short_label = "Exc [E]" },
						watches = { keymap = "W", label = "Watches [W]", short_label = "Watch [W]" },
						threads = { keymap = "T", label = "Threads [T]", short_label = "Thr [T]" },
						repl = { keymap = "R", label = "REPL [R]", short_label = "REPL [R]" },
						console = {
							keymap = "C",
							label = "Console [C]",
							short_label = "󰆍 [C]",
						},
					},
					custom_sections = {}, -- Thêm custom nếu cần (e.g., logpoints)
					controls = {
						enabled = true, -- Bật buttons control (play, step, etc.) trong winbar
						position = "right",
						buttons = {
							"play",
							"step_into",
							"step_over",
							"step_out",
							"step_back",
							"run_last",
							"terminate",
							"disconnect",
						},
					},
				},
				render = { -- Sort/filter vars (thay filter: sort alphabet, skip private _vars cho Flutter clean)
					sort_variables = function(a, b)
						local name_a = a.name or ""
						local name_b = b.name or ""
						-- Skip private vars (Dart convention: _private)
						if string.match(name_a, "^_") then
							return false
						end
						if string.match(name_b, "^_") then
							return true
						end
						-- Sort alphabet nếu cả hai valid
						return name_a < name_b
					end,
				},
				-- Icons tùy chọn (default tốt, nhưng customize nếu dùng icons khác)
				icons = {
					play = "▶",
					step_into = "↳",
					step_over = "→",
					step_out = "↱",
					enabled = "●",
					disabled = "○",
				},
				-- Help border (default nil)
				help = { border = "rounded" },
				-- Switchbuf cho jumping windows (default "usetab,uselast")
				switchbuf = "usetab,uselast",
			},
		},
	},
	config = function()
		local dap = require("dap")

		-- Adapter cho Dart/Flutter (built-in, dùng fvm path)
		dap.adapters.dart = {
			type = "executable",
			command = vim.fn.system("which dart"):gsub("\n", ""),
			args = { "debug_adapter" },
		}

		-- Configurations cơ bản cho Dart/Flutter (tích hợp setup_project của bạn)
		dap.configurations.dart = {
			-- Default launch
			{
				type = "dart",
				request = "launch",
				name = "Launch Flutter",
				dartSdkPath = vim.fn.expand("$HOME/.fvm/versions/stable/dart-sdk/bin"), -- Adjust nếu path khác; hoặc dùng vim.fn.expand("$HOME/flutter/bin/cache/dart-sdk")
				flutterSdkPath = vim.fn.expand("$HOME/.fvm/versions/stable"), -- fvm path
				program = "${workspaceFolder}/lib/main.dart",
				cwd = "${workspaceFolder}",
			},
			{
				type = "dart",
				request = "launch",
				name = "Web - Dev",
				dartSdkPath = vim.fn.expand("$HOME/.fvm/versions/stable/dart-sdk/bin"),
				flutterSdkPath = vim.fn.expand("$HOME/.fvm/versions/stable"),
				program = "${workspaceFolder}/lib/main.dart",
				cwd = "${workspaceFolder}",
				toolArgs = { "-d", "chrome", "--web-port=4000", "--wasm" },
			},
			-- Profile mode
			{
				type = "dart",
				request = "launch",
				name = "Profile Mode",
				dartSdkPath = vim.fn.expand("$HOME/.fvm/versions/stable/dart-sdk/bin"),
				flutterSdkPath = vim.fn.expand("$HOME/.fvm/versions/stable"),
				program = "${workspaceFolder}/lib/main.dart",
				cwd = "${workspaceFolder}",
				flutterMode = "profile",
			},
		}

		-- Load từ .vscode/launch.json nếu project có (tùy chọn, override trên)
		-- require("dap.ext.vscode").load_launchjs()
	end,
	keys = {
		{
			"<leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Toggle Breakpoint",
		},
		{
			"<leader>dc",
			function()
				require("dap").continue()
			end,
			desc = "Continue Debug",
		},
		{
			"<leader>di",
			function()
				require("dap").step_into()
			end,
			desc = "Step Into",
		},
		{
			"<leader>do",
			function()
				require("dap").step_over()
			end,
			desc = "Step Over",
		},
		{
			"<leader>du",
			function()
				require("dap").step_out()
			end,
			desc = "Step Out",
		},
		{
			"<leader>dr",
			function()
				require("dap").repl.open()
			end,
			desc = "Open DAP REPL",
		},
		{
			"<leader>dv",
			function()
				require("dap-view").toggle()
			end,
			desc = "Toggle DAP View",
		},
		-- Thêm cho winbar sections (dùng trong debug session)
		{
			"<leader>dws",
			function()
				require("dap-view").open("scopes")
			end,
			desc = "Open Scopes View",
		},
		{
			"<leader>dww",
			function()
				require("dap-view").open("watches")
			end,
			desc = "Open Watches View",
		},
	},
}

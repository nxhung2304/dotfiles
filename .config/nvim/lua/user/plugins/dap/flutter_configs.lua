local dap = require("dap")

-- Adapter cho Dart/Flutter (sử dụng dart built-in)
dap.adapters.dart = {
	type = "executable",
	command = "dart", -- Hoặc full path nếu dùng fvm: vim.fn.system('which dart'):gsub('\n', '')
	args = { "debug_adapter" },
}

-- Configurations cơ bản (có thể override từ .vscode/launch.json nếu có)
dap.configurations.dart = {
	{
		type = "dart",
		request = "launch",
		name = "Launch Flutter",
		dartSdkPath = vim.fn.expand("$HOME/.fvm/versions/stable/dart-sdk")
			or vim.fn.expand("$HOME/flutter/bin/cache/dart-sdk"), -- Adjust nếu path khác
		flutterSdkPath = vim.fn.expand("$HOME/flutter"), -- Hoặc fvm path
		program = "${workspaceFolder}/lib/main.dart", -- Default entrypoint
		cwd = "${workspaceFolder}",
		-- Thêm toolArgs nếu cần device cụ thể, ví dụ: toolArgs = { '-d', 'chrome' }
	},
	{
		type = "dart",
		request = "launch",
		name = "Web - Dev",
		dartSdkPath = vim.fn.expand("$HOME/flutter/bin/cache/dart-sdk"),
		flutterSdkPath = vim.fn.expand("$HOME/flutter"),
		program = "${workspaceFolder}/lib/main.dart",
		cwd = "${workspaceFolder}",
		toolArgs = { "-d", "chrome", "--web-port=4000", "--wasm" },
	},
	-- Thêm cho Profile mode nếu cần
	{
		type = "dart",
		request = "launch",
		name = "Profile Mode",
		dartSdkPath = vim.fn.expand("$HOME/flutter/bin/cache/dart-sdk"),
		flutterSdkPath = vim.fn.expand("$HOME/flutter"),
		program = "${workspaceFolder}/lib/main.dart",
		cwd = "${workspaceFolder}",
		flutterMode = "profile",
	},
}

-- Load configs từ .vscode/launch.json nếu project có (tùy chọn, tiện lợi)
require("dap.ext.vscode").load_launchjs()

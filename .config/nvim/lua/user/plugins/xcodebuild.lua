return {
	"wojciech-kulik/xcodebuild.nvim",
	ft = "swift",
	dependencies = {
		"folke/snacks.nvim",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("xcodebuild").setup({})

		local project_config = require("xcodebuild.project.config")
		project_config.load_settings()

		local has_xcode_project = #vim.fn.glob("*.xcodeproj", false, true) > 0
			or #vim.fn.glob("*.xcworkspace", false, true) > 0
			or vim.fn.filereadable("Package.swift") == 1

		if has_xcode_project and not project_config.is_configured() then
			vim.schedule(function()
				vim.cmd("XcodebuildSetup")
			end)
		end
	end,
	keys = {
		{ "<leader>X", "<cmd>XcodebuildPicker<cr>", ft = "swift", desc = "Show Xcodebuild Actions" },
		{ "<leader>xb", "<cmd>XcodebuildBuild<cr>", ft = "swift", desc = "Build Project" },
		{ "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", ft = "swift", desc = "Build & Run Project" },
		{ "<leader>xt", "<cmd>XcodebuildTest<cr>", ft = "swift", desc = "Run Tests" },
		{ "<leader>xT", "<cmd>XcodebuildTestClass<cr>", ft = "swift", desc = "Run Current Test Class" },
		{ "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", ft = "swift", desc = "Toggle Xcodebuild Logs" },
		{ "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", ft = "swift", desc = "Select Device" },
		{ "<leader>xe", "<cmd>XcodebuildTestExplorerToggle<cr>", ft = "swift", desc = "Toggle Test Explorer" },
	},
}

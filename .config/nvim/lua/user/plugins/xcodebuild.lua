return {
	"wojciech-kulik/xcodebuild.nvim",
	ft = "swift",
	dependencies = {
		"folke/snacks.nvim",
		"MunifTanjim/nui.nvim",
	},
	opts = {},
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

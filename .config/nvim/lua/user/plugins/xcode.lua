return {
	"wojciech-kulik/xcodebuild.nvim",
	ft = { "swift", "objc" },
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("xcodebuild").setup({})
	end,
	cond = function()
		local cwd = vim.fn.getcwd()
		local xcodeproj_files = vim.fn.glob(cwd .. "/*.xcodeproj")
		return xcodeproj_files ~= ""
	end,
	keys = {
		{ "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build Project" } },
		{ "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & Run Project" } },
		{ "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Xcodebuild Logs" } },
		{ "<leader>xs", "<cmd>XcodebuildFailingSnapshots<cr>", { desc = "Show Failing Snapshots" } },
		{ "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select Device" } },
		{ "<leader>xq", "<cmd>Telescope quickfix<cr>", { desc = "Show QuickFix List" } },
		{ "<leader>xx", "<cmd>XcodebuildQuickfixLine<cr>", { desc = "Quickfix Line" } },
		{ "<leader>xa", "<cmd>XcodebuildCodeActions<cr>", { desc = "Show Code Actions" } },
	},
}


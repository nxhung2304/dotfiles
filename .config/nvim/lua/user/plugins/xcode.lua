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
		{ "n", "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build Project" } },
		{ "n", "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & Run Project" } },
		{ "n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Xcodebuild Logs" } },
		{ "n", "<leader>xs", "<cmd>XcodebuildFailingSnapshots<cr>", { desc = "Show Failing Snapshots" } },
		{ "n", "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select Device" } },
		{ "n", "<leader>xq", "<cmd>Telescope quickfix<cr>", { desc = "Show QuickFix List" } },
		{ "n", "<leader>xx", "<cmd>XcodebuildQuickfixLine<cr>", { desc = "Quickfix Line" } },
		{ "n", "<leader>xa", "<cmd>XcodebuildCodeActions<cr>", { desc = "Show Code Actions" } },
	},
}

return {
	"wojciech-kulik/xcodebuild.nvim",
	ft = { "swift", "objc" },
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	config = function()
		local progress_handle

		require("xcodebuild").setup({
			show_build_progress_bar = false,
			logs = {
				notify = function(message, severity)
					local fidget = require("fidget")
					if progress_handle then
						progress_handle.message = message
						if not message:find("Loading") then
							progress_handle:finish()
							progress_handle = nil
							if vim.trim(message) ~= "" then
								fidget.notify(message, severity)
							end
						end
					else
						fidget.notify(message, severity)
					end
				end,
				notify_progress = function(message)
					local progress = require("fidget.progress")

					if progress_handle then
						progress_handle.title = ""
						progress_handle.message = message
					else
						progress_handle = progress.handle.create({
							message = message,
							lsp_client = { name = "xcodebuild.nvim" },
						})
					end
				end,
			},
			integrations = {
				xcodebuild_offline = {
					enabled = true,
				},
			},
		})
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

return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot", -- lazy load khi chạy lệnh Copilot
		event = { "InsertEnter" }, -- hoặc giữ "InsertEnter", "CmdlineEnter" nếu bạn muốn
		config = function()
			require("copilot").setup({
				copilot_node_command = vim.fn.expand("~/.asdf/shims/node"),
				suggestion = {
					enabled = true,
					auto_trigger = true, -- giống auto_trigger cũ của bạn
					debounce = 75, -- giữ nguyên 75ms như cũ
					hide_during_completion = true, -- rất quan trọng nếu bạn dùng nvim-cmp
					trigger_on_accept = true,

					keymap = {
						accept = "<Tab>", -- giữ nguyên như cũ
						accept_word = "<C-Right>",
						accept_line = "<C-j>",
						next = "<C-n>",
						prev = "<C-p>",
						dismiss = "<C-c>",
						-- toggle_auto_trigger không có keymap mặc định, mình sẽ làm riêng bên dưới
					},
				},

				panel = {
					enabled = true,
					auto_refresh = false,
					keymap = {
						jump_prev = "[[",
						jump_next = "]]",
						accept = "<CR>",
						refresh = "gr",
						open = "<M-CR>",
					},
					layout = {
						position = "bottom",
						ratio = 0.4,
					},
				},

				filetypes = {
					yaml = false,
					markdown = false,
					help = false,
					gitcommit = false,
					gitrebase = false,
					hgcommit = false,
					svn = false,
					cvs = false,
					["."] = false, -- tắt tất cả filetype khác trừ những cái bạn bật
				},

				-- Tùy chọn bổ sung (nên có)
				disable_limit_reached_message = true, -- giống config cũ của bạn
			})

			-- copilot.lua stores the runtime toggle state in this buffer var;
			-- nil means "use the config default", which is auto_trigger = true above.
			local function auto_trigger_on()
				local state = vim.b.copilot_suggestion_auto_trigger
				if state == nil then
					return true
				end
				return state
			end

			vim.keymap.set("n", "<leader>ct", function()
				local suggestion = require("copilot.suggestion")
				suggestion.toggle_auto_trigger()
				vim.notify("Copilot auto-trigger: " .. (auto_trigger_on() and "ON" or "OFF"), vim.log.levels.INFO)
			end, { desc = "Toggle Copilot auto-trigger" })

			vim.keymap.set("n", "<leader>cD", function()
				local suggestion = require("copilot.suggestion")
				if auto_trigger_on() then
					suggestion.toggle_auto_trigger()
					vim.notify("Copilot inline suggestion: OFF", vim.log.levels.INFO)
				end
				suggestion.dismiss()
			end, { desc = "Disable Copilot inline suggestion" })
		end,
	},
}

local u = require("user.plugins.rails.utils")
local t = require("user.plugins.rails.test")

return {
	{
		"tpope/vim-rails",
		lazy = false,
		init = function()
			local function apply_hl()
				vim.api.nvim_set_hl(0, "TestRunning", { fg = "#fabd2f", bold = true })
				vim.api.nvim_set_hl(0, "TestPassed", { fg = "#b8bb26", bold = true })
				vim.api.nvim_set_hl(0, "TestFailed", { fg = "#fb4934", bold = true })
			end
			apply_hl()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
		end,
		keys = {
			-- Test
			{
				"<leader>tc",
				function()
					u.rails_guard(function()
						t.run_test("bundle exec rails test " .. vim.fn.expand("%:p") .. ":" .. vim.fn.line("."))
					end)
				end,
				desc = "Test at Cursor",
			},
			{
				"<leader>tf",
				function()
					u.rails_guard(function()
						t.run_test("bundle exec rails test " .. vim.fn.expand("%:p"))
					end)
				end,
				desc = "Test File",
			},
			{
				"<leader>ta",
				function()
					u.rails_guard(function()
						t.run_test("bundle exec rails test")
					end)
				end,
				desc = "Test All",
			},
			{
				"<leader>tl",
				function()
					u.rails_guard(function()
						local last = t.get_last_test_cmd()
						if last then
							t.run_test(last)
						else
							vim.notify("No previous test command", vim.log.levels.WARN)
						end
					end)
				end,
				desc = "Rerun Last Test",
			},
			{ "<leader>tt", t.toggle_test_panel, desc = "Toggle Test Panel" },
			{
				"]f",
				function()
					local win = t.get_test_win_id()
					if not (win and vim.api.nvim_win_is_valid(win)) then
						vim.notify("No test output open", vim.log.levels.WARN)
						return
					end
					local buf = vim.api.nvim_win_get_buf(win)
					local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
					local cur = vim.api.nvim_win_get_cursor(win)[1]
					for i = cur + 1, #lines do
						if lines[i]:match("^Failure:") or lines[i]:match("^Error:") then
							vim.api.nvim_set_current_win(win)
							vim.api.nvim_win_set_cursor(win, { i, 0 })
							return
						end
					end
					vim.notify("No more failures", vim.log.levels.INFO)
				end,
				desc = "Next test failure",
			},
			{
				"[f",
				function()
					local win = t.get_test_win_id()
					if not (win and vim.api.nvim_win_is_valid(win)) then
						vim.notify("No test output open", vim.log.levels.WARN)
						return
					end
					local buf = vim.api.nvim_win_get_buf(win)
					local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
					local cur = vim.api.nvim_win_get_cursor(win)[1]
					for i = cur - 1, 1, -1 do
						if lines[i]:match("^Failure:") or lines[i]:match("^Error:") then
							vim.api.nvim_set_current_win(win)
							vim.api.nvim_win_set_cursor(win, { i, 0 })
							return
						end
					end
					vim.notify("No more failures", vim.log.levels.INFO)
				end,
				desc = "Prev test failure",
			},
			{
				"<leader>to",
				function()
					local win = t.get_test_win_id()
					if win and vim.api.nvim_win_is_valid(win) then
						vim.api.nvim_set_current_win(win)
					else
						vim.notify("No test output open", vim.log.levels.WARN)
					end
				end,
				desc = "Focus Test Output",
			},
			-- Navigation
			{ "<leader>rc", "<cmd>Econtroller<cr>", desc = "Controller" },
			{ "<leader>rm", "<cmd>Emodel<cr>", desc = "Model" },
			{ "<leader>rv", "<cmd>Eview<cr>", desc = "View" },
			{ "<leader>ru", "<cmd>Eunittest<cr>", desc = "Unittest" },
			{ "<leader>rf", "<cmd>Efixture<cr>", desc = "Fixture" },
			{ "<leader>ri", u.i18n_jump, desc = "i18n Jump / Grep" },
			{ "<leader>rI", u.i18n_files, desc = "i18n Files" },
			{ "<leader>rr", "<cmd>Eroutes<cr>", desc = "Routes" },
			{ "<leader>rh", "<cmd>Ehelper<cr>", desc = "Helper" },

			-- Runtime
			{
				"<leader>Rc",
				function()
					u.rails_guard(function()
						u.run_cmd("bundle exec rails console", "rails console", { interactive = true })
					end)
				end,
				desc = "Rails Console",
			},
			{
				"<leader>Rs",
				function()
					u.rails_guard(function()
						vim.ui.input({ prompt = "rails server ", default = "" }, function(args)
							local cmd = "bundle exec rails server"
							if args and args ~= "" then
								cmd = cmd .. " " .. args
							end
							u.tmux_named_window("server", cmd)
						end)
					end)
				end,
				desc = "Rails Server",
			},
			{
				"<leader>Rl",
				function()
					u.rails_guard(function()
						u.tmux_named_window("logs", "tail -f log/development.log")
					end)
				end,
				desc = "Rails Logs",
			},
			{
				"<leader>Rm",
				function()
					u.rails_guard(function()
						u.run_cmd("bundle exec rails db:migrate", "db:migrate")
					end)
				end,
				desc = "DB Migrate",
			},
			{
				"<leader>RS",
				function()
					u.rails_guard(function()
						u.run_cmd("bundle exec rails db:seed", "db:seed")
					end)
				end,
				desc = "DB Seed",
			},
			{
				"<leader>RR",
				function()
					u.rails_guard(function()
						u.run_cmd("bundle exec rails db:migrate:reset", "db:migrate:reset")
					end)
				end,
				desc = "DB Migrate reset",
			},
			{
				"<leader>Rg",
				function()
					u.rails_guard(function()
						vim.ui.input({ prompt = "rails generate ", default = "" }, function(args)
							if args and args ~= "" then
								u.run_cmd("bundle exec rails generate " .. args, "generate " .. args)
							end
						end)
					end)
				end,
				desc = "Rails Generate",
			},
			{
				"<leader>Re",
				function()
					u.rails_guard(u.console_send_selection)
				end,
				mode = "v",
				desc = "Send selection to console",
			},
			{
				"<leader>Rr",
				function()
					u.rails_guard(u.routes_grep)
				end,
				desc = "Routes grep",
			},
			-- Rubocop
			{
				"<leader>Rb",
				function()
					local file = vim.fn.expand("%:.")
					u.run_cmd("bundle exec rubocop " .. vim.fn.expand("%:p"), "rubocop " .. file)
				end,
				desc = "Rubocop Check File",
			},
			{
				"<leader>RB",
				function()
					u.run_cmd("bundle exec rubocop", "rubocop")
				end,
				desc = "Rubocop Check All",
			},
			{
				"<leader>Rf",
				function()
					local file = vim.fn.expand("%:.")
					u.run_cmd("bundle exec rubocop -A " .. vim.fn.expand("%:p"), "rubocop -A " .. file)
				end,
				desc = "Rubocop Fix File",
			},
			{
				"<leader>RF",
				function()
					u.run_cmd("bundle exec rubocop -A", "rubocop -A")
				end,
				desc = "Rubocop Fix All",
			},
		},
	},
}

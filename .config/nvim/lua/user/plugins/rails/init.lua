local u = require("user.plugins.rails.utils")

return {
	{
		"tpope/vim-rails",
		lazy = false,
		keys = {
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

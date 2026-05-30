local function tmux_named_window(name, cmd)
	local full = string.format(
		"silent !tmux new-window -n '%s' '%s' 2>/dev/null || tmux select-window -t '%s'",
		name, cmd, name
	)
	vim.cmd(full)
end

return {
	{
		"preservim/vimux",
		lazy = false,
		config = function()
			vim.g["VimuxOrientation"] = "v"
			vim.g["VimuxHeight"] = "33"
		end,
	},
	{
		"tpope/vim-rails",
		lazy = false,
		dependencies = { "preservim/vimux" },
		keys = {
			-- Test
			{
				"<leader>tc",
				function()
					local file = vim.fn.expand("%:p")
					local line = vim.fn.line(".")
					vim.cmd("VimuxRunCommand('bundle exec rails test " .. file .. ":" .. line .. "')")
				end,
				desc = "Test at Cursor",
			},
			{
				"<leader>tf",
				function()
					local file = vim.fn.expand("%:p")
					vim.cmd("VimuxRunCommand('bundle exec rails test " .. file .. "')")
				end,
				desc = "Test File",
			},
			{ "<leader>ta", "<cmd>VimuxRunCommand('bundle exec rails test')<cr>", desc = "Test All" },
			{ "<leader>tl", "<cmd>VimuxRunLastCommand<cr>", desc = "Rerun Last Test" },
			-- Navigation
			{ "<leader>rc", "<cmd>Econtroller<cr>", desc = "Controller" },
			{ "<leader>rm", "<cmd>Emodel<cr>", desc = "Model" },
			{ "<leader>rv", "<cmd>Eview<cr>", desc = "View" },
			{ "<leader>ru", "<cmd>Eunittest<cr>", desc = "Unittest" },
			{ "<leader>rf", "<cmd>Efixture<cr>", desc = "Fixture" },
			{ "<leader>rR", "<cmd>Emigration<cr>", desc = "Migration" },
			{ "<leader>rr", "<cmd>Einitializer<cr>", desc = "Routes" },
			-- Tmux named windows (persistent)
			{
				"<leader>rC",
				function() tmux_named_window("console", "bundle exec rails console") end,
				desc = "Rails Console",
			},
			{
				"<leader>rS",
				function() tmux_named_window("server", "bundle exec rails server") end,
				desc = "Rails Server",
			},
			{
				"<leader>rL",
				function() tmux_named_window("logs", "tail -f log/development.log") end,
				desc = "Rails Logs",
			},
			-- Vimux (short-lived)
			{
				"<leader>rD",
				"<cmd>VimuxRunCommand('bundle exec rails db:migrate')<cr>",
				desc = "DB Migrate",
			},
			{
				"<leader>rg",
				"<cmd>VimuxPromptCommand('bundle exec rails generate ')<cr>",
				desc = "Rails Generate",
			},
			-- Rubocop
			{
				"<leader>rb",
				function()
					local file = vim.fn.expand("%:p")
					vim.cmd("VimuxRunCommand('bundle exec rubocop " .. file .. "')")
				end,
				desc = "Rubocop Check File",
			},
			{
				"<leader>rB",
				"<cmd>VimuxRunCommand('bundle exec rubocop')<cr>",
				desc = "Rubocop Check All",
			},
			{
				"<leader>rF",
				function()
					local file = vim.fn.expand("%:p")
					vim.cmd("VimuxRunCommand('bundle exec rubocop -A " .. file .. "')")
				end,
				desc = "Rubocop Fix File",
			},
			{
				"<leader>ra",
				"<cmd>VimuxRunCommand('bundle exec rubocop -A')<cr>",
				desc = "Rubocop Fix All",
			},
		},
	},
}

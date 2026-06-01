local function tmux_named_window(name, cmd)
	local full = string.format(
		"silent !tmux new-window -n '%s' '%s' 2>/dev/null || tmux select-window -t '%s'",
		name, cmd, name
	)
	vim.cmd(full)
end

local test_pane_id = nil
local last_test_cmd = nil

local function run_test(cmd)
	last_test_cmd = cmd

	-- Check if the tracked pane still exists
	if test_pane_id then
		local alive = vim.trim(vim.fn.system(
			"tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qF '" .. test_pane_id .. "' && echo 1 || echo 0"
		))
		if alive ~= "1" then test_pane_id = nil end
	end

	if not test_pane_id then
		local id = vim.trim(vim.fn.system("tmux new-window -n 'test' -P -F '#{pane_id}'"))
		if vim.v.shell_error ~= 0 or id == "" then
			vim.notify("Failed to open tmux window", vim.log.levels.ERROR)
			return
		end
		test_pane_id = id
	end

	vim.fn.system("tmux send-keys -t " .. test_pane_id .. " " .. vim.fn.shellescape(cmd) .. " Enter")
	vim.fn.system("tmux select-window -t " .. test_pane_id)
end

return {
	{
		"preservim/vimux",
		lazy = false,
		config = function()
			vim.g["VimuxOrientation"] = "h"
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
					run_test("bundle exec rails test " .. file .. ":" .. line)
				end,
				desc = "Test at Cursor",
			},
			{
				"<leader>tf",
				function()
					local file = vim.fn.expand("%:p")
					run_test("bundle exec rails test " .. file)
				end,
				desc = "Test File",
			},
			{
				"<leader>ta",
				function() run_test("bundle exec rails test") end,
				desc = "Test All",
			},
			{
				"<leader>tl",
				function()
					if last_test_cmd then
						run_test(last_test_cmd)
					else
						vim.notify("No previous test command", vim.log.levels.WARN)
					end
				end,
				desc = "Rerun Last Test",
			},
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

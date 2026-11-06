local Utils = require("user.core.utils")
local map = Utils.keymap

local function get_gh_accounts()
	local out = vim.fn.system("gh auth status 2>&1")
	local accounts = {}
	for account in out:gmatch("account (%S+)") do
		table.insert(accounts, account)
	end
	return accounts
end

local function switch_gh_account(on_switched)
	local accounts = get_gh_accounts()
	if #accounts == 0 then
		vim.notify("No gh accounts found", vim.log.levels.WARN, { title = "gh" })
		return
	end
	vim.ui.select(accounts, { prompt = "Switch GitHub account:" }, function(choice)
		if not choice then
			return
		end
		vim.fn.jobstart({ "gh", "auth", "switch", "--user", choice }, {
			on_exit = function(_, code)
				vim.schedule(function()
					if code == 0 then
						vim.notify("Switched to " .. choice, vim.log.levels.INFO, { title = "gh" })
						on_switched()
					else
						vim.notify("Failed to switch to " .. choice, vim.log.levels.ERROR, { title = "gh" })
					end
				end)
			end,
		})
	end)
end

local open_tab
open_tab = function(url_cmd)
	local stderr = {}
	vim.fn.jobstart({
		"sh",
		"-c",
		"set -o pipefail; " .. url_cmd .. " | xargs ~/.local/bin/scripts/open-or-focus-tab",
	}, {
		stderr_buffered = true,
		on_stderr = function(_, data)
			if data then
				vim.list_extend(stderr, data)
			end
		end,
		on_exit = function(_, code)
			if code ~= 0 then
				local msg = vim.trim(table.concat(stderr, "\n"))
				vim.schedule(function()
					vim.notify(
						"Cannot open in browser" .. (msg ~= "" and (":\n" .. msg) or ""),
						vim.log.levels.ERROR,
						{ title = "gitsigns" }
					)
					switch_gh_account(function()
						open_tab(url_cmd)
					end)
				end)
			end
		end,
	})
end

local function open_line_pr()
	local file = vim.fn.expand("%:p")
	local line = vim.fn.line(".")
	local url_cmd = string.format(
		"sha=$(git blame -L %d,%d --porcelain -- %s | head -1 | cut -d' ' -f1); "
			.. "gh api repos/{owner}/{repo}/commits/$sha/pulls --jq '.[0].html_url // empty'",
		line,
		line,
		vim.fn.shellescape(file)
	)
	open_tab(url_cmd)
end

-- ---------------------------------------------------------------------------
-- diffbandit.nvim helpers (also used from Neogit's diff popup)
-- ---------------------------------------------------------------------------

-- Run a diffbandit API call; its functions return `nil, err` on failure.
local function diffbandit(fn_name, ...)
	local ok, err = require("diffbandit")[fn_name](...)
	if not ok and err then
		vim.notify(tostring(err), vim.log.levels.ERROR, { title = "DiffBandit" })
	end
end

-- Default branch of the repo (origin/HEAD), falling back to main/master.
local function default_branch(root)
	local cmd = { "git" }
	if root then
		vim.list_extend(cmd, { "-C", root })
	end
	local function git(args)
		local out = vim.fn.systemlist(vim.list_extend(vim.deepcopy(cmd), args))
		return vim.v.shell_error == 0 and out[1] or nil
	end
	local ref = git({ "rev-parse", "--abbrev-ref", "origin/HEAD" })
	if ref and ref ~= "origin/HEAD" then
		return ref
	end
	for _, name in ipairs({ "main", "master" }) do
		if git({ "rev-parse", "--verify", "--quiet", "refs/heads/" .. name }) then
			return name
		end
	end
	return "main"
end

local function review_branch(root)
	diffbandit("git", { root = root, mode = "all", base = default_branch(root) })
end

local FILE_SECTIONS = { untracked = true, unstaged = true, staged = true }

-- Extra "DiffBandit" column in Neogit's diff popup (`d`).
-- Uppercase keys so nothing collides with Neogit's own d/h/r/p/u/s/w/c/t.
local function neogit_diff_popup(builder)
	local function root()
		return require("neogit.lib.git").repo.worktree_root
	end

	-- "do what I mean" on the thing under the cursor:
	-- file in status -> that file, commit (status/log/commit view) -> that commit
	local function this(popup)
		popup:close()
		local item = popup:get_env("item") or {}
		local section = (popup:get_env("section") or {}).name
		local name = item.name

		if type(name) == "table" then
			-- log view: { "<first>~1", "<first>", ... }
			name = name[2] or name[1]
		end

		if FILE_SECTIONS[section] then
			local mode = section == "staged" and "staged" or nil
			if type(name) == "string" and name ~= "" then
				diffbandit("git_file", root() .. "/" .. name, { root = root(), mode = mode })
			else
				diffbandit("git", { root = root(), mode = mode })
			end
		elseif type(name) == "string" and name ~= "" then
			diffbandit("git_commit", name, { root = root() })
		else
			diffbandit("git", { root = root() })
		end
	end

	builder
		:new_action_group("DiffBandit")
		:action("D", "this", this)
		:action("W", "worktree", function(popup)
			popup:close()
			diffbandit("git", { root = root() })
		end)
		:action("S", "staged", function(popup)
			popup:close()
			diffbandit("git", { root = root(), mode = "staged" })
		end)
		:action("B", "branch vs default", function(popup)
			popup:close()
			review_branch(root())
		end)
		:action("L", "log", function(popup)
			popup:close()
			diffbandit("git_log", { root = root() })
		end)
end

local HERDR_WORKTREE_WORKSPACE_SCRIPT = vim.fn.expand("~/dotfiles/scripts/herdr/worktree-workspace")

local function find_other_worktree_for_branch(branch_name)
	local current_root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
	local worktree_path
	for _, line in ipairs(vim.fn.systemlist({ "git", "worktree", "list", "--porcelain" })) do
		local path = line:match("^worktree (.+)$")
		if path then
			worktree_path = path
		elseif line == "branch refs/heads/" .. branch_name and worktree_path ~= current_root then
			return worktree_path
		end
	end
end

local function jump_to_branch_worktree(checkout)
	if not vim.env.HERDR_ENV then
		return
	end
	local worktree_path = find_other_worktree_for_branch(checkout.branch_name)
	if not worktree_path then
		return
	end
	vim.system({ HERDR_WORKTREE_WORKSPACE_SCRIPT, "open", worktree_path }, {}, function(result)
		if result.code == 0 then
			vim.system({ "herdr", "notification", "show", "Switched worktree", "--body", checkout.branch_name })
			return
		end
		vim.schedule(function()
			vim.notify(
				"Cannot switch to worktree of " .. checkout.branch_name .. ":\n" .. vim.trim(result.stderr or ""),
				vim.log.levels.ERROR,
				{ title = "Neogit" }
			)
		end)
	end)
end

return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			on_attach = function(_)
				local gs = require("gitsigns")

				-- Navigation
				map("n", "]g", gs.next_hunk, { desc = "Next hunk" })
				map("n", "[g", gs.prev_hunk, { desc = "Prev hunk" })

				-- Actions
				map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage hunk" })
				map("v", "<leader>gs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "Stage hunk (visual)" })
				map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
				map("n", "<leader>gS", gs.stage_buffer, { desc = "Stage buffer" })
				map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset hunk" })
				map("v", "<leader>gr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "Reset hunk (visual)" })
				map("n", "<leader>gR", gs.reset_buffer, { desc = "Reset buffer" })
				-- Floating popup preview (real buffer, cursor can enter to yank the
				-- old/deleted lines). Pressing again focuses the popup.
				map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
				map("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "Toggle line blame" })
				map("n", "<leader>gc", "<cmd>GitBlameCopyGitHubURL<cr>", { desc = "Copy file URL Remote" })
				map("n", "<leader>gl", open_line_pr, { desc = "Open PR of current line's commit" })
				map("n", "<leader>gh", function()
					open_tab("gh pr view --json url -q .url")
				end, { desc = "Open PR in browser" })
				map("n", "<leader>gP", function()
					open_tab("gh repo view --json url -q .url | xargs -I{} echo {}/pulls")
				end, { desc = "Open PRs list in browser" })
				map("n", "<leader>gi", function()
					open_tab("gh repo view --json url -q .url | xargs -I{} echo {}/issues")
				end, { desc = "Open Issues list in browser" })
				map("n", "<leader>gD", function()
					Snacks.picker.git_branches({
						format = function(item)
							local hl = item.current and "SnacksPickerGitBranchCurrent" or "SnacksPickerGitBranch"
							local name = item.detached and "(detached HEAD)" or item.branch
							return { { name, hl } }
						end,
						actions = {
							git_branch_del_confirm = function(picker, item)
								if not (item and item.branch) then
									return
								end
								local branch = item.branch
								Snacks.picker.util.cmd({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, function(data)
									vim.schedule(function()
										if data[1] and data[1]:match(branch) then
											vim.notify(
												"Cannot delete the current branch.",
												vim.log.levels.ERROR,
												{ title = "Git" }
											)
											return
										end
										Utils.confirm(("Delete branch %q?"):format(branch), function()
											Snacks.picker.util.cmd({ "git", "branch", "-D", branch }, function()
												vim.notify(
													"Deleted branch `" .. branch .. "`",
													vim.log.levels.INFO,
													{ title = "Git" }
												)
												vim.cmd.checktime()
												picker:refresh()
											end, { cwd = picker:cwd() })
										end)
									end)
								end, { cwd = picker:cwd() })
							end,
						},
						win = {
							input = {
								keys = {
									["<c-x>"] = { "git_branch_del_confirm", mode = { "n", "i" } },
								},
							},
						},
					})
				end, { desc = "Delete branch (<c-x> in picker)" })
			end,

			-- Blame config
			current_line_blame = true,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
				delay = 100,
				ignore_whitespace = false,
				virt_text_priority = 100,
				use_focus = true,
			},
			current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
		},
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"m00qek/baleia.nvim", -- optional
		},
		cmd = "Neogit",
		opts = {
			hooks = {
				PreBranchCheckout = jump_to_branch_worktree,
			},
			-- No diffview/codediff installed: Neogit hides its own diff actions,
			-- so diffbandit is wired in through the popup builder instead.
			builders = {
				NeogitDiffPopup = neogit_diff_popup,
			},
		},
		keys = {
			{ "<leader>go", "<cmd>Neogit<cr>", desc = "Show Neogit UI" },
		},
	},
	{
		-- Side-by-side diff viewer (branch/PR review, commits, hunk staging)
		"CoreyKaylor/diffbandit.nvim",
		cmd = {
			"DiffBandit",
			"DiffBanditBuffers",
			"DiffBanditFolderDiff",
			"DiffBanditGit",
			"DiffBanditGitCurrent",
			"DiffBanditGitMenu",
			"DiffBanditGitLog",
			"DiffBanditGitCommit",
			"DiffBanditGitCompare",
			"DiffBanditCommitPanel",
			"DiffBanditMerge",
		},
		keys = {
			{ "<leader>gd", "<cmd>DiffBanditGit<cr>", desc = "Diff working tree" },
			{ "<leader>gf", "<cmd>DiffBanditGitCurrent<cr>", desc = "Diff current file" },
			{
				"<leader>gB",
				function()
					review_branch()
				end,
				desc = "Review branch vs default branch",
			},
			{ "<leader>gL", "<cmd>DiffBanditGitLog<cr>", desc = "Git log review" },
		},
		opts = {},
	},
	{
		"nxhung2304/conflict.nvim",
		config = function()
			require("conflict").setup({
				keymaps = { leader = "<leader>C" },
				ui = { markers = false }, -- clickable action buttons
				detect = { anywhere = true }, -- detect outside git merge
				colors = {
					current = "#56CC7A",
					incoming = "#40A6FF",
					base = "#FFCC66",
				},
			})
			-- conflict.nvim maps <LeftMouse> even when ui.markers = false
			-- the mapping does nothing then, but swallows statusline clicks
			vim.keymap.del("n", "<LeftMouse>")
		end,
	},
}

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

local function run_diffbandit(fn_name, ...)
	local ok, err = require("diffbandit")[fn_name](...)
	if not ok and err then
		vim.notify(tostring(err), vim.log.levels.ERROR, { title = "DiffBandit" })
	end
end

local function read_git_output(root, args)
	local cmd = { "git" }
	if root then
		vim.list_extend(cmd, { "-C", root })
	end

	local output = vim.fn.systemlist(vim.list_extend(cmd, args))
	return vim.v.shell_error == 0 and output[1] or nil
end

local BASE_BRANCH_CANDIDATES = { "develop", "main", "master", "origin/develop", "origin/main", "origin/master" }

local function count_commits_only_on_head(root, ref)
	return tonumber(read_git_output(root, { "rev-list", "--count", ref .. "..HEAD" }))
end

local function find_base_branch(root)
	local base_branch, fewest_commits
	for _, ref in ipairs(BASE_BRANCH_CANDIDATES) do
		local commit_count = count_commits_only_on_head(root, ref)
		local is_existing_ref = commit_count ~= nil
		local is_closer_base = not fewest_commits or (is_existing_ref and commit_count < fewest_commits)
		if is_existing_ref and is_closer_base then
			base_branch, fewest_commits = ref, commit_count
		end
	end

	return base_branch
end

local function find_fork_point(root)
	local base_branch = find_base_branch(root)
	if not base_branch then
		return nil
	end

	local fork_point = read_git_output(root, { "merge-base", base_branch, "HEAD" })
	if not fork_point then
		return nil
	end

	return read_git_output(root, { "rev-parse", "--short", fork_point })
end

local function review_branch_changes(root)
	local fork_point = find_fork_point(root)
	if not fork_point then
		vim.notify("No develop, main or master branch found", vim.log.levels.WARN, { title = "DiffBandit" })
		return
	end

	run_diffbandit("git", { root = root, mode = "all", base = fork_point })
end

local NEOGIT_FILE_SECTIONS = { untracked = true, unstaged = true, staged = true }

local function get_neogit_root()
	return require("neogit.lib.git").repo.worktree_root
end

local function get_popup_target(popup)
	local item_name = (popup:get_env("item") or {}).name
	if type(item_name) == "table" then
		item_name = item_name[2] or item_name[1]
	end

	local section_name = (popup:get_env("section") or {}).name
	return section_name, item_name
end

local function open_diffbandit_for_popup_target(popup)
	local section_name, item_name = get_popup_target(popup)
	local root = get_neogit_root()
	local has_item_name = type(item_name) == "string" and item_name ~= ""
	local is_file_section = NEOGIT_FILE_SECTIONS[section_name]
	local mode = section_name == "staged" and "staged" or nil

	if is_file_section and has_item_name then
		run_diffbandit("git_file", root .. "/" .. item_name, { root = root, mode = mode })
	elseif is_file_section then
		run_diffbandit("git", { root = root, mode = mode })
	elseif has_item_name then
		run_diffbandit("git_commit", item_name, { root = root })
	else
		run_diffbandit("git", { root = root })
	end
end

local function close_popup_then(action)
	return function(popup)
		popup:close()
		action(popup)
	end
end

local function add_diffbandit_actions_to_neogit_diff_popup(builder)
	builder
		:new_action_group("DiffBandit")
		:action("D", "this", close_popup_then(open_diffbandit_for_popup_target))
		:action("W", "worktree", close_popup_then(function()
			run_diffbandit("git", { root = get_neogit_root() })
		end))
		:action("S", "staged", close_popup_then(function()
			run_diffbandit("git", { root = get_neogit_root(), mode = "staged" })
		end))
		:action("B", "branch changes", close_popup_then(function()
			review_branch_changes(get_neogit_root())
		end))
		:action("L", "log", close_popup_then(function()
			run_diffbandit("git_log", { root = get_neogit_root() })
		end))
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
			builders = {
				NeogitDiffPopup = add_diffbandit_actions_to_neogit_diff_popup,
			},
		},
		keys = {
			{ "<leader>go", "<cmd>Neogit<cr>", desc = "Show Neogit UI" },
		},
	},
	{
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
					review_branch_changes()
				end,
				desc = "Review branch changes",
			},
			{ "<leader>gH", "<cmd>DiffBanditGitLog<cr>", desc = "Git log review" },
			{ "<leader>gm", "<cmd>DiffBanditMerge<cr>", desc = "Resolve merge conflict" },
		},
		opts = {},
	},
}

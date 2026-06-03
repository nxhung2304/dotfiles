return {
	"kyazdani42/nvim-tree.lua",
	init = function()
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1

		require("user.core.sidebar").register({
			id       = "files",
			label    = "Files",
			icon     = "󰉋",
			no_badge = true,
			open = function()
				vim.cmd("NvimTreeOpen")
			end,
			close = function() vim.cmd("NvimTreeClose") end,
			is_open = function()
				local ok, view = pcall(require, "nvim-tree.view")
				return ok and view.is_visible() or false
			end,
			get_win = function()
				local ok, view = pcall(require, "nvim-tree.view")
				return ok and view.get_winnr() or nil
			end,
		})
	end,
	opts = {
		sync_root_with_cwd = true,
		respect_buf_cwd = true,
		update_focused_file = {
			enable = true,
			update_root = false,
		},
		filters = {
			custom = {
				"^.git$",
			},
			dotfiles = false,
		},
		live_filter = {
			prefix = "[FILTER]: ",
			always_show_folders = false,
		},
		renderer = {
			icons = {
				show = {
					file         = true,
					folder       = true,
					folder_arrow = true,
					git          = true,
				},
				glyphs = {
					default = "",
					symlink = "",
					git = {
						unstaged = "󰏫",
						staged = "󰱒",
						unmerged = "",
						renamed = "󰁕",
						deleted = "󰍷",
						untracked = "󰝒",
						ignored = "󰈉",
					},
					folder = {
						default = "",
						open = "",
						empty = "",
						empty_open = "",
						symlink = "",
					},
				},
			},
		},
		git = {
			ignore        = false,
			show_on_dirs  = false,
		},
		view = {
			relativenumber = true,
			width = 52,
		},
		on_attach = function(bufnr)
			local api = require("nvim-tree.api")
			api.config.mappings.default_on_attach(bufnr)
			local o = { buffer = bufnr, nowait = true }
			vim.keymap.set("n", "<Tab>", function() require("user.core.sidebar").next() end, o)
			vim.keymap.set("n", "<S-Tab>", function() require("user.core.sidebar").prev() end, o)
			vim.keymap.set("n", ">", function() require("user.core.sidebar").resize(4) end, o)
			vim.keymap.set("n", "<lt>", function() require("user.core.sidebar").resize(-4) end, o)
			vim.keymap.set("n", "~", function() api.tree.change_root(vim.fn.getcwd(-1, -1)) end, o)

			-- Find folder by name, cd into it; press "-" to go back up
			vim.keymap.set("n", "f", function()
				local cwd = vim.fn.getcwd()
				vim.ui.input({ prompt = "󰉋 Find folder: " }, function(input)
					if not input or input == "" then return end
					local dirs = vim.fn.systemlist({
						"fd", "--type", "d", "--hidden", "--exclude", ".git",
						"--absolute-path", input, cwd,
					})
					if #dirs == 0 then
						vim.notify("No folder matching: " .. input, vim.log.levels.WARN)
					elseif #dirs == 1 then
						api.tree.change_root(dirs[1])
					else
						vim.ui.select(dirs, {
							prompt = "Select folder:",
							format_item = function(d) return d:gsub(cwd .. "/", "") end,
						}, function(choice)
							if choice then api.tree.change_root(choice) end
						end)
					end
				end)
			end, { buffer = bufnr, nowait = true, desc = "nvim-tree: Find Folder" })
		end,
	},
	keys = {
		{ "<leader>e", function() require("user.core.sidebar").toggle() end, desc = "Toggle sidebar" },
		{ "<leader>.", function()
			require("user.core.sidebar").switch("files", { focus = false })
			vim.schedule(function() vim.cmd("NvimTreeFindFile") end)
		end, desc = "Find file in NvimTree" },
	},
}

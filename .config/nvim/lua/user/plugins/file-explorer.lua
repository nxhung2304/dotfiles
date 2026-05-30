return {
	"kyazdani42/nvim-tree.lua",
	init = function()
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1

		require("user.core.sidebar").register({
			id = "files",
			label = "Files",
			icon = "",
			open = function()
				vim.cmd("NvimTreeOpen")
				vim.schedule(function()
					local ok, view = pcall(require, "nvim-tree.view")
					if not ok then return end
					local win = view.get_winnr()
					if win then require("user.core.sidebar").set_tabbar(win) end
				end)
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
		renderer = {
			icons = {
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
			ignore = false,
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
		end,
	},
	keys = {
		{ "<leader>e", function() require("user.core.sidebar").toggle() end, desc = "Toggle sidebar" },
		{ "<leader>.", "<cmd>NvimTreeFindFile<cr>", desc = "Find file in NvimTree" },
	},
}

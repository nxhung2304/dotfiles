return {
	"kyazdani42/nvim-tree.lua",
	setup = function()
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
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
					default = "",
					symlink = "",
					git = {
						-- unstaged = "",
						-- staged = "S",
						-- unmerged = "",
						-- renamed = "➜",
						-- deleted = "",
						-- untracked = "U",
						-- ignored = "◌",

						unstaged = "󰏫", -- Modified/changed
						staged = "󰱒", -- Staged/added
						unmerged = "", -- Conflict
						renamed = "󰁕", -- Renamed
						deleted = "󰍷", -- Deleted
						untracked = "󰝒", -- New/untracked
						ignored = "󰈉", -- Ignored
					},
					folder = {
						default = "",
						open = "",
						empty = "",
						empty_open = "",
						symlink = "",
					},
				},
			},
		},
		git = {
			ignore = false,
		},
		view = {
			relativenumber = true, -- Show relative number in tree
			adaptive_size = true, -- Set width nvimtree by fit all elements
		},
	},
	keys = {
		{
			"<leader>e",
			function()
				local view = require("nvim-tree.view")
				if view.is_visible() then
					vim.cmd("NvimTreeClose")
				else
					pcall(function()
						require("aerial").close()
					end)

					vim.cmd("NvimTreeOpen")
				end
			end,
			desc = "Toggle NvimTree",
		},
		{ "<leader>.", "<cmd>NvimTreeFindFile<cr>", desc = "Find file in NvimTree" },
	},
}

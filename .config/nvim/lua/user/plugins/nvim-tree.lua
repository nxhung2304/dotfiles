return {
	"kyazdani42/nvim-tree.lua",
	cmd = {
		"NvimTreeToggle",
	},
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
						unstaged = "",
						staged = "S",
						unmerged = "",
						renamed = "➜",
						deleted = "",
						untracked = "U",
						ignored = "◌",
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
		-- { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle NvimTree" },
		-- {
		-- 	"<leader>e", -- hoặc phím tắt bạn thường dùng cho NvimTree
		-- 	function()
		-- 		-- Đóng debug panels bên trái trước
		-- 		require("edgy").close("dapui_scopes")
		-- 		require("edgy").close("dapui_breakpoints")
		-- 		require("edgy").close("flutterToolsOutline")
		--
		-- 		-- Sau đó toggle NvimTree
		-- 		vim.cmd("NvimTreeToggle")
		-- 	end,
		-- 	desc = "Toggle NvimTree and close debug panels",
		-- },
		-- {
		-- 	"<leader>e",
		-- 	function()
		-- 		local view = require("nvim-tree.view")
		-- 		if view.is_visible() then
		-- 			vim.cmd("NvimTreeClose")
		-- 		else
		-- 			-- Đóng debug panels một cách chắc chắn
		-- 			local edgy = require("edgy")
		-- 			pcall(function()
		-- 				edgy.close("dapui_scopes")
		-- 				edgy.close("dapui_breakpoints")
		-- 				edgy.close("flutterToolsOutline")
		-- 			end)
		--
		-- 			-- Hoặc thử đóng toàn bộ left panel
		-- 			edgy.close("left")
		--
		-- 			-- Chờ một chút rồi mở NvimTree
		-- 			vim.defer_fn(function()
		-- 				vim.cmd("NvimTreeOpen")
		-- 			end, 100)
		-- 		end
		-- 	end,
		-- 	desc = "Toggle NvimTree",
		-- },
		{
			"<leader>e",
			function()
				local view = require("nvim-tree.view")
				if view.is_visible() then
					vim.cmd("NvimTreeClose")
				else
					-- Đóng DAP UI hoàn toàn
					pcall(function()
						require("dapui").close()
					end)

					-- Chờ một chút rồi mở NvimTree
					-- vim.defer_fn(function()
						vim.cmd("NvimTreeOpen")
					-- end, 100)
				end
			end,
			desc = "Toggle NvimTree",
		},
		{ "<leader>.", "<cmd>NvimTreeFindFile<cr>", desc = "Find file in NvimTree" },
	},
}

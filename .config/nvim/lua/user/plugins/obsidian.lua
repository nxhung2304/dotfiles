return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	keys = {
		{ "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
		{ "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Quick switch" },
		{ "<leader>of", "<cmd>Obsidian quick_switch<cr>", desc = "Find files" },
		{ "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search notes" },
		{ "<leader>od", "<cmd>Obsidian today<cr>", desc = "Daily note (today)" },
		{ "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "Daily note (yesterday)" },
		{ "<leader>ot", "<cmd>Obsidian template<cr>", desc = "Insert template" },
		{ "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
		{ "<leader>ol", "<cmd>Obsidian links<cr>", desc = "Links" },
		{ "<leader>or", "<cmd>Obsidian rename<cr>", desc = "Rename note" },
		{ "<leader>op", "<cmd>Obsidian paste_img<cr>", desc = "Paste image" },
		{ "<leader>ow", "<cmd>Obsidian workspace<cr>", desc = "Switch workspace" },
	},
	config = function(_, opts)
		require("obsidian").setup(opts)

		-- obsidian.nvim hardcodes --no-config, ignoring RIPGREP_CONFIG_PATH.
		-- search/init.lua copies function refs from ripgrep.lua at load time,
		-- so we must patch obsidian.search (not obsidian.search.ripgrep).
		local search = require("obsidian.search")
		for _, fn_name in ipairs({ "build_search_cmd", "build_find_cmd", "build_grep_cmd" }) do
			local orig = search[fn_name]
			search[fn_name] = function(...)
				local cmd = orig(...)
				table.insert(cmd, 2, "--follow")
				return cmd
			end
		end
	end,
	opts = {
		legacy_commands = false,
		workspaces = {
			{
				name = "personal",
				path = "~/vaults/personal",
			},
		},
		daily_notes = {
			folder = "dailies",
			date_format = "%Y-%m-%d",
		},
		templates = {
			folder = "templates",
		},
		picker = {
			name = "snacks.picker",
		},
		attachments = {
			folder = "assets/imgs",
		},
	},
}

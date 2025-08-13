return {
	"MagicDuck/grug-far.nvim",
	-- Note (lazy loading): grug-far.lua defers all it's requires so it's lazy by default
	-- additional lazy config to defer loading is not really needed...
	cmd = {
		"GrugFar",
	},
	config = function()
		-- optional setup call to override plugin options
		-- alternatively you can set options with vim.g.grug_far = { ... }
		require("grug-far").setup({
			-- options, see Configuration section below
			-- there are no required options atm
		})
	end,
	keys = {
		{ "<leader>sg", "<cmd>GrugFar<cr>", desc = "Find and Replace" },
		{
			"<leader>sw",
			function()
				local search_term
				if vim.fn.mode() == "v" then
					-- Visual mode: lấy selected text
					local start_pos = vim.fn.getpos("'<")
					local end_pos = vim.fn.getpos("'>")
					local lines = vim.fn.getline(start_pos[2], end_pos[2])
					search_term = table.concat(lines, "\n")
				else
					-- Normal mode: lấy word under cursor
					search_term = vim.fn.expand("<cword>")
				end

				require("grug-far").open({
					prefills = {
						search = search_term,
					},
				})
			end,
			mode = { "n", "v" },
			desc = "Search word/selection",
		},
	},
}

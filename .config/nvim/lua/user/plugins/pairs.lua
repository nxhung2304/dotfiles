-- Replaces mini.pairs: nvim-autopairs handles bracket/quote pairing and
-- integrates with nvim-cmp. `end` insertion is handled by vim-endwise, which
-- (unlike nvim-autopairs' endwise rules) checks whether a matching `end`
-- already exists below the cursor before inserting one.
return {
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			local npairs = require("nvim-autopairs")
			npairs.setup({
				check_ts = true, -- treesitter-aware pairing
				fast_wrap = {}, -- <M-e> to wrap the next word/pair
			})

			-- Add ( after selecting a function/method from nvim-cmp.
			local ok, cmp = pcall(require, "cmp")
			if ok then
				local cmp_autopairs = require("nvim-autopairs.completion.cmp")
				cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
			end
		end,
	},
	{
		"tpope/vim-endwise",
		event = "InsertEnter",
	},
}

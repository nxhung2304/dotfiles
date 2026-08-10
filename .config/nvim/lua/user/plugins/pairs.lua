-- Replaces mini.pairs + vim-endwise: nvim-autopairs handles bracket/quote
-- pairing, `end` insertion (endwise rules), and integrates with nvim-cmp.
return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	config = function()
		local npairs = require("nvim-autopairs")
		npairs.setup({
			check_ts = true, -- treesitter-aware pairing
			fast_wrap = {}, -- <M-e> to wrap the next word/pair
		})

		-- Wisely add `end` in Ruby, Lua, etc. (vim-endwise replacement).
		-- Triggers on <CR>, which flows through cmp's <CR> confirm fallback.
		npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
		npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))

		-- Add ( after selecting a function/method from nvim-cmp.
		local ok, cmp = pcall(require, "cmp")
		if ok then
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end
	end,
}

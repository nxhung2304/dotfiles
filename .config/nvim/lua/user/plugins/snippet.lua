return {
	{
		"echasnovski/mini.snippets",
		version = false,
		event = "InsertEnter",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			local gen_loader = require("mini.snippets").gen_loader
			require("mini.snippets").setup({
				snippets = {
					gen_loader.from_lang(),
				},
			})
		end,
	},
}

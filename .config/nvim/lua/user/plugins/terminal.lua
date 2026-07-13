return {
	"akinsho/toggleterm.nvim",
	version = "*",
	opts = {
		size = function(term)
			if term.direction == "horizontal" then
				return 15
			elseif term.direction == "vertical" then
				return math.floor(vim.o.columns * 0.38)
			end
		end,
		open_mapping = [[<c-\>]],
		direction = "float",
		float_opts = { border = "curved" },
		shade_terminals = false,
		start_in_insert = true,
		persist_size = true,
		close_on_exit = true,
	},
}

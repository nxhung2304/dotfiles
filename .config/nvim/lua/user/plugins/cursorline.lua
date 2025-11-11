return {
	"ya2s/nvim-cursorline",
	opts = {
		cursorline = {
			enable = true,
			timeout = 100,
			number = false,
		},
		cursorword = {
			enable = true,
			min_length = 2,
			hl = { underline = true },
		},
	},
}

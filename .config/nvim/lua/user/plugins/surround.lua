-- Keymaps differ from nvim-surround: sa=add, sd=delete, sr=replace (vs ys/ds/cs)
return {
	"echasnovski/mini.surround",
	version = false,
	event = "VeryLazy",
	opts = {
		mappings = {
			add = "sa",
			delete = "sd",
			replace = "sr",
			find = "sf",
			find_left = "sF",
			highlight = "sh",
			update_n_lines = "sn",
		},
	},
}

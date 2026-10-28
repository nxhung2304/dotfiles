local persist_file = vim.fn.stdpath("data") .. "/colorscheme.txt"

local function read_saved()
	local f = io.open(persist_file, "r")
	if f then
		local name = f:read("*l")
		f:close()
		if name and name ~= "" then
			return name
		end
	end
	return "gruvbox"
end

local function save_colorscheme(name)
	local f = io.open(persist_file, "w")
	if f then
		f:write(name)
		f:close()
	end
end

local function follow_saved_colorscheme()
	if vim.fn.filereadable(persist_file) == 0 then
		save_colorscheme(read_saved())
	end
	local watcher = vim.uv.new_fs_event()
	watcher:start(persist_file, {}, function()
		vim.defer_fn(function()
			local name = read_saved()
			if name ~= vim.g.colors_name then
				pcall(vim.cmd.colorscheme, name)
			end
		end, 100)
	end)
end

local theme_switch_script = vim.fs.joinpath(
	vim.fs.dirname(vim.fs.dirname(vim.fn.resolve(vim.fn.stdpath("config")))),
	"scripts",
	"theme-switch"
)

local function pick_theme()
	local themes = vim.fn.systemlist({ theme_switch_script, "--list" })
	vim.ui.select(themes, { prompt = "Theme" }, function(theme)
		if theme then
			vim.system({ theme_switch_script, theme })
		end
	end)
end

local function highlight_fg(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
end

local function apply_statusline()
	local bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
	vim.api.nvim_set_hl(0, "StatusLine", { fg = highlight_fg("Function"), bg = bg })
	vim.api.nvim_set_hl(0, "StatusLineNC", { fg = highlight_fg("Comment"), bg = bg })
end

return {
	{
		"rockyzhang24/arctic.nvim",
		dependencies = { "rktjmp/lush.nvim" },
		name = "arctic",
		branch = "v2",
		lazy = false,
		priority = 1000,
		config = function() end,
	},
	{
		"ellisonleao/gruvbox.nvim",
		lazy = false,
		priority = 999,
		config = function()
			-- Reapply statusline overrides on every colorscheme change
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = apply_statusline,
			})

			-- :CS — pick a theme and apply it to every app via scripts/theme-switch
			vim.api.nvim_create_user_command("CS", pick_theme, { nargs = 0 })

			vim.keymap.set("n", "<leader>uc", "<cmd>CS<cr>", { desc = "Pick theme (all apps)" })

			if not pcall(vim.cmd.colorscheme, read_saved()) then
				vim.cmd.colorscheme("gruvbox")
			end
			follow_saved_colorscheme()
		end,
	},
	{ "sainnhe/gruvbox-material", lazy = false, priority = 1000 },
	{ "sainnhe/everforest", lazy = false, priority = 1000 },
	{ "gbprod/nord.nvim", lazy = false, priority = 1000 },
}

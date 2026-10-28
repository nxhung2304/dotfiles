local persist_file = vim.fn.stdpath("data") .. "/colorscheme.txt"
local fallback_colorscheme = "gruvbox"

local function read_saved_theme()
	local lines = vim.fn.filereadable(persist_file) == 1 and vim.fn.readfile(persist_file) or {}
	local colorscheme = lines[1]
	if not colorscheme or colorscheme == "" then
		colorscheme = fallback_colorscheme
	end

	local globals = {}
	for index = 2, #lines do
		local name, value = lines[index]:match("^([%w_]+)=(.*)$")
		if name then
			globals[name] = value
		end
	end
	return { colorscheme = colorscheme, globals = globals }
end

local function apply_saved_theme()
	local theme = read_saved_theme()
	for name, value in pairs(theme.globals) do
		vim.g[name] = value
	end

	local applied, error_message = pcall(vim.cmd.colorscheme, theme.colorscheme)
	if not applied then
		vim.notify("Theme " .. theme.colorscheme .. " failed: " .. error_message, vim.log.levels.WARN)
	end
	return applied
end

local function saved_theme_text()
	return table.concat(vim.fn.readfile(persist_file), "\n")
end

local function follow_saved_theme()
	if vim.fn.filereadable(persist_file) == 0 then
		vim.fn.writefile({ fallback_colorscheme }, persist_file)
	end

	local applied_theme_text = saved_theme_text()
	local watcher = vim.uv.new_fs_event()
	watcher:start(persist_file, {}, function()
		vim.defer_fn(function()
			local theme_text = saved_theme_text()
			if theme_text ~= applied_theme_text then
				applied_theme_text = theme_text
				apply_saved_theme()
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

local function apply_flat_style()
	local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
	local groups_on_editor_background = {
		"NormalFloat",
		"SignColumn",
		"FoldColumn",
		"DiagnosticSignError",
		"DiagnosticSignWarn",
		"DiagnosticSignInfo",
		"DiagnosticSignHint",
		"DiagnosticSignOk",
	}
	for _, group in ipairs(groups_on_editor_background) do
		local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
		highlight.bg = normal_bg
		vim.api.nvim_set_hl(0, group, highlight)
	end
	vim.api.nvim_set_hl(0, "FloatBorder", { fg = highlight_fg("WinSeparator"), bg = normal_bg })
	vim.api.nvim_set_hl(0, "FloatTitle", { fg = highlight_fg("Title"), bg = normal_bg, bold = true })
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
				callback = function()
					apply_statusline()
					apply_flat_style()
				end,
			})

			-- :CS — pick a theme and apply it to every app via scripts/theme-switch
			vim.api.nvim_create_user_command("CS", pick_theme, { nargs = 0 })

			vim.keymap.set("n", "<leader>uc", "<cmd>CS<cr>", { desc = "Pick theme (all apps)" })

			if not apply_saved_theme() then
				vim.cmd.colorscheme(fallback_colorscheme)
			end
			follow_saved_theme()
		end,
	},
	{ "sainnhe/gruvbox-material", lazy = false, priority = 1000 },
	{ "sainnhe/everforest", lazy = false, priority = 1000 },
	{ "gbprod/nord.nvim", lazy = false, priority = 1000 },
	{ "zenbones-theme/zenbones.nvim", dependencies = { "rktjmp/lush.nvim" }, lazy = false, priority = 1000 },
	{ "savq/melange-nvim", lazy = false, priority = 1000 },
	{ "vague-theme/vague.nvim", lazy = false, priority = 1000 },
}

local function augroup(name)
	return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight text on yank",
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
	end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	desc = "Auto reload file when changed externally",
	pattern = "*",
	callback = function()
		if vim.fn.mode() ~= "c" then
			vim.o.autoread = true
			vim.opt.updatetime = 1000
			vim.cmd("checktime")
		end
	end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
	desc = "Show notification when file changed",
	pattern = "*",
	callback = function()
		vim.api.nvim_echo({
			{ "File changed on disk. Buffer reloaded.", "WarningMsg" },
		}, true, {})
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = augroup("wrap_spell"),
	pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "Install solargraph if not present when LSP attaches",
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.name == "solargraph" then
			vim.defer_fn(function()
				if vim.fn.filereadable(vim.fn.expand("~/.asdf/shims/solargraph")) == 0 then
					vim.notify("Installing solargraph...", vim.log.levels.INFO)
					vim.fn.system("gem install solargraph && asdf reshim ruby")
					vim.cmd("LspRestart")
				end
			end, 1000)
		end
	end,
})

vim.api.nvim_create_augroup("CenterCursor", { clear = true })

vim.api.nvim_create_autocmd("WinEnter", {
	desc = "Center cursor when entering a window",
	group = "CenterCursor",
	callback = function()
		vim.cmd("normal! zz")
	end,
})

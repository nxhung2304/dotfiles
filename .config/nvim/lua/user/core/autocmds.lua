local function augroup(name)
	return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local marker = vim.fn.stdpath("cache") .. "/restart_file"
		if vim.fn.filereadable(marker) == 1 then
			local file = vim.fn.readfile(marker)[1]
			vim.fn.delete(marker)
			if file and file ~= "" and vim.fn.filereadable(file) == 1 then
				vim.schedule(function()
					vim.cmd("edit " .. vim.fn.fnameescape(file))
				end)
			end
		end
	end,
})

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

-- Disable render-markdown in diff windows (e.g. codediff preview) to prevent flickering
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
	desc = "Disable render-markdown in diff windows",
	callback = function()
		local ok, rm = pcall(require, "render-markdown")
		if not ok then
			return
		end
		if vim.wo.diff then
			rm.disable()
		elseif vim.bo.filetype == "markdown" then
			rm.enable()
		end
	end,
})



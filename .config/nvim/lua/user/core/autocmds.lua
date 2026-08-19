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
		if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
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
	desc = "Install ruby-lsp if not present when LSP attaches",
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.name == "ruby_lsp" then
			vim.defer_fn(function()
				if vim.fn.filereadable(vim.fn.expand("~/.asdf/shims/ruby-lsp")) == 0 then
					vim.notify("Installing ruby-lsp...", vim.log.levels.INFO)
					vim.fn.system("gem install ruby-lsp && asdf reshim ruby")
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

-- Auto-save 1s after leaving insert mode (debounced; cancelled if insert is re-entered)
local autosave_timer = vim.uv.new_timer()
local function save_current_buffer()
	if vim.bo.modified and vim.bo.buftype == "" and not vim.bo.readonly and vim.fn.expand("%") ~= "" then
		vim.cmd.update()
		vim.notify(
			vim.fn.expand("%:t") .. " saved at " .. vim.fn.strftime("%H:%M:%S"),
			vim.log.levels.INFO,
			{ title = "AutoSave" }
		)
	end
end

vim.api.nvim_create_autocmd("InsertEnter", {
	desc = "Cancel pending auto-save while typing",
	callback = function()
		autosave_timer:stop()
	end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
	desc = "Auto-save 1s after leaving insert mode",
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()
		autosave_timer:stop()
		autosave_timer:start(1000, 0, vim.schedule_wrap(function()
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_call(bufnr, save_current_buffer)
			end
		end))
	end,
})

-- Disable render-markdown in diff windows to prevent flickering
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



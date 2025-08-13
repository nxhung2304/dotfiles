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
	desc = "Open help page in horizontal",
	pattern = "help",
	callback = function()
		vim.cmd("wincmd L")
		vim.cmd("vertical resize 80")
	end,
})

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

augroup("DartLSPAutoAttach", { clear = true })

autocmd({ "BufEnter", "BufWinEnter" }, {
	group = "DartLSPAutoAttach",
	pattern = "*.dart",
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		local clients = vim.lsp.get_active_clients({ bufnr = buf })

		local has_dartls = false
		for _, client in pairs(clients) do
			if client.name == "dartls" then
				has_dartls = true
				break
			end
		end

		if not has_dartls then
			local dartls_clients = vim.lsp.get_active_clients({ name = "dartls" })
			if #dartls_clients > 0 then
				vim.lsp.buf_attach_client(buf, dartls_clients[1].id)
				print("Auto-attached dartls to buffer " .. buf)
			end
		end
	end,
})

autocmd("LspAttach", {
	group = "DartLSPAutoAttach",
	callback = function(event)
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client and client.name == "dartls" then
			vim.defer_fn(function()
				require("user.core.utils").attach_dartls_to_all_buffers()
			end, 1000)
		end
	end,
})

autocmd("User", {
	pattern = "DapBreakpointSet",
	callback = function()
		require("edgy").goto_main()
	end,
})

-- Tự động mở debug layout khi bắt đầu debug
autocmd("User", {
	pattern = "DapSessionInitialized",
	callback = function()
		-- Mở debug layout
		require("edgy").open("left")
		require("edgy").open("bottom")
		require("edgy").open("right")
	end,
})

-- Tự động đóng debug layout khi kết thúc debug
autocmd("User", {
	pattern = "DapSessionTerminated",
	callback = function()
		vim.defer_fn(function()
			-- require("edgy").close("dapui_scopes")
			-- require("edgy").close("dapui_stacks")
			-- require("edgy").close("dap-repl")
			require("edgy").close("log")
		end, 100)
	end,
})

-- Flutter-specific autocmds
autocmd("User", {
	pattern = "FlutterRunPre",
	callback = function()
		require("edgy").open("bottom")
	end,
})

autocmd("User", {
	pattern = "FlutterRunPost",
	callback = function()
		require("edgy").open("right")
	end,
})

autocmd("ColorScheme", {
	callback = function()
		-- Override highlights với màu xanh
		local overrides = {
			QuickFixLine = { bg = "#264f78", fg = "NONE" },
			Search = { bg = "#264f78", fg = "#ffffff" },
			IncSearch = { bg = "#264f78", fg = "#ffffff" },
			CurSearch = { bg = "#264f78", fg = "#ffffff" },
			MatchParen = { bg = "#264f78", fg = "NONE" },
		}

		for group, opts in pairs(overrides) do
			vim.api.nvim_set_hl(0, group, opts)
		end
	end,
})

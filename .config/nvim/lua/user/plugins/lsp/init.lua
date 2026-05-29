local Configs = require("user.core.configs")

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			{
				"SmiteshP/nvim-navic",
				opts = {
					icons = {},
					highlight = true,
				},
			},
		},
		config = function()
			-- diagnostics
			vim.diagnostic.config({
				virtual_text = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = Configs.icons.diagnostics[1].text,
						[vim.diagnostic.severity.WARN] = Configs.icons.diagnostics[2].text,
						[vim.diagnostic.severity.HINT] = Configs.icons.diagnostics[3].text,
						[vim.diagnostic.severity.INFO] = Configs.icons.diagnostics[4].text,
					},
				},
				update_in_insert = true,
				underline = true,
				severity_sort = true,
				float = {
					focusable = false,
					style = "minimal",
					border = "rounded",
					source = "always",
					header = "",
					prefix = "",
				},
			})

			-- attach servers
			local servers = {
				-- "ruby_lsp",
        "solargraph",
				"bashls",
				"cssls",
				"emmet_ls",
				"eslint",
				"jsonls",
				"lua_ls",
				"phpactor",
				"pyright",
				"sourcekit",
				"tailwindcss",
				"ts_ls",
				"volar",
				"vtsls",
				"kotlin_language_server",
			}

			local utils = require("user.core.utils")

			vim.o.winbar = "%{%v:lua.require('user.core.utils').get_filepath_with_navic()%}"

			-- Setup LSP capabilities for completion
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			for _, server in pairs(servers) do
				local opts = {
					on_attach = utils.lsp_on_attach,
					capabilities = capabilities,
				}
				local has_custom_opts, server_custom_opts = pcall(require, "user.plugins.lsp.settings." .. server)
				if has_custom_opts then
					opts = vim.tbl_deep_extend("force", opts, server_custom_opts)
				end
				vim.lsp.config(server, opts)
				vim.lsp.enable(server)
			end
		end,
	},
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				-- LSP Servers
				"bash-language-server",
				"cssls",
				"emmet_ls",
				"eslint",
				"jsonls",
				"lua_language_server",
				"phpactor",
				"pyright",
				-- "ruby-lsp",
        "solargraph",
				"tailwindcss-language-server",
				"typescript-language-server",
				"vtsls",
				"vue-language-server",
				-- Formatters & Linters
				"clang_format",
				"clangd",
				"cspell",
				"deno",
				"html",
				"prettier",
				"rubocop",
				"shfmt",
				"stylua",
				-- Build tools
				"kotlin_language_server",
			},
			ui = {
				border = "rounded",
			},
			PATH = "prepend",
		},
	},
	{ "mfussenegger/nvim-lint", event = { "BufReadPre", "BufNewFile" } },
	{ "williamboman/mason-lspconfig.nvim", event = { "BufReadPre", "BufNewFile" } },
	{
		"onsails/lspkind.nvim",
		event = "BufReadPre",
	},
}

local Configs = require("user.core.configs")

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
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
				-- "solargraph",
				"phpactor",
				"vtsls",
				"eslint",
				"jsonls",
				"emmet_ls",
				"volar",
				"lua_ls",
				"pyright",
				"tailwindcss",
				"sourcekit",
				"cssls",
				"kotlin_language_server",
				"ruby_lsp",
				"ts_ls",
			}

			local lspconfig = require("lspconfig")
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
				lspconfig[server].setup(opts)
			end
		end,
	},
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = {
			ensure_installed = {
				"clang_format",
				"clangd",
				"cspell",
				"css_lsp",
				"deno",
				"html_lsp",
				"kotlin_language_server",
				"lua_language_server",
				"phpactor",
				"prettier",
				"rubocop",
				-- "solargraph",
				"stylua",
				"typescript_language_server",
				"vue-language-server",
				"ruby-lsp",
				"vtsls",
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

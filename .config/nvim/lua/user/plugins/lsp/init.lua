local Configs = require("user.core.configs")

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
		},
		config = function()
			-- diagnostics
			vim.diagnostic.config({
				virtual_text = {
					prefix = "", -- Could be '■', '▎', 'x', etc.
					source = "if_many", -- Show source 'always', 'if_many', or 'never'
					spacing = 4,
					current_line = true,
				},
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = Configs.icons.diagnostics[1].text,
						[vim.diagnostic.severity.WARN] = Configs.icons.diagnostics[2].text,
						[vim.diagnostic.severity.HINT] = Configs.icons.diagnostics[3].text,
						[vim.diagnostic.severity.INFO] = Configs.icons.diagnostics[4].text,
					},
				},
				update_in_insert = false,
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
				"ruby_lsp",
				"bashls",
				"cssls",
				"emmet_ls",
				"eslint",
				"gopls",
				"htmx",
				"jsonls",
				"lua_ls",
				"phpactor",
				"pyright",
				"sourcekit",
				"tailwindcss",
				"volar",
				"vtsls",
				"kotlin_lsp",
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
			ui = {
				border = "rounded",
			},
			PATH = "prepend",
		},
	},
	{
		-- mason.nvim itself does NOT process `ensure_installed`; this plugin does.
		-- It installs any missing tool below on startup (run_on_start).
		-- Names must be Mason registry package names (dashes, not lspconfig ids).
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				-- LSP Servers
				"bash-language-server",
				"css-lsp",
				"emmet-ls",
				"eslint-lsp",
				"gopls",
				"jdtls",
				"json-lsp",
				"kotlin-lsp",
				"lua-language-server",
				"phpactor",
				"pyright",
				"ruby-lsp",
				"tailwindcss-language-server",
				"typescript-language-server",
				"vtsls",
				"vue-language-server",
				-- Formatters & Linters
				"clang-format",
				"clangd",
				"cspell",
				"delve",
				"deno",
				"gofumpt",
				"goimports",
				"google-java-format",
				"ktlint",
				"swiftlint",
				"html-lsp",
				"prettier",
				"rubocop",
				"shfmt",
				"stylua",
			},
			run_on_start = true,
			auto_update = false,
		},
	},
	{ "williamboman/mason-lspconfig.nvim", event = { "BufReadPre", "BufNewFile" } },
}

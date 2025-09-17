local Configs = require("user.core.configs")

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{
				"SmiteshP/nvim-navic",
				opts = {
					icons = {
						File = "",
						Module = "",
						Namespace = "",
						Package = "",
						Class = "",
						Method = "",
						Property = "",
						Field = "",
						Constructor = "",
						Enum = "",
						Interface = "",
						Function = "",
						Variable = "",
						Constant = "",
						String = "",
						Number = "",
						Boolean = "",
						Array = "",
						Object = "",
						Key = "",
						Null = "",
						EnumMember = "",
						Struct = "",
						Event = "",
						Operator = "",
						TypeParameter = "",
					},
					highlight = true,
				},
			},
		},
		opts = function()
			return {
				diagnostics = {
					-- disable virtual text
					virtual_text = true,
					-- show signs
					signs = {
						active = Configs.icons.diagnostics,
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
				},
				inlay_hints = { enabled = true },
			}
		end,
		config = function()
			-- diagnostics
			for _, sign in ipairs(Configs.icons.diagnostics) do
				vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
			end

			-- attach servers
			local servers = {
				"solargraph",
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
				"kotlin_language_server"
			}

			local lspconfig = require("lspconfig")
			local navic = require("nvim-navic")
			local keymap = require("user.core.utils").keymap
			local utils = require("user.core.utils")

			vim.o.winbar = "%{%v:lua.require('user.core.utils').get_filepath_with_navic()%}"

			-- Setup LSP capabilities for completion
			local capabilities = require('cmp_nvim_lsp').default_capabilities()

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
				"solargraph",
				"stylua",
				"typescript_language_server",
				"vue-language-server",
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

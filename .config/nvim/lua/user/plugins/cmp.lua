return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lua",
			"saadparwaiz1/cmp_luasnip",
		},
		opts = function()
			local luasnip = require("luasnip")
			local cmp = require("cmp")
			require("luasnip/loaders/from_vscode").lazy_load()
			require("luasnip.loaders.from_vscode").lazy_load({ paths = "~/.config/nvim/lua/user/snippets" })
			local col = vim.fn.col(".") - 1
			local check_backspace = col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
					-- { name = "minuet" },
				},
			})
			return {
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body) -- For `luasnip` users.
					end,
				},
				mapping = {
					["<C-k>"] = cmp.mapping.select_prev_item(),
					["<C-j>"] = cmp.mapping.select_next_item(),
					["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
					["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
					["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
					["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
					["<C-e>"] = cmp.mapping({
						i = cmp.mapping.abort(),
						c = cmp.mapping.close(),
					}),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expandable() then
							luasnip.expand()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, {
						"i",
						"s",
					}),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, {
						"i",
						"s",
					}),
				},
				formatting = {
					fields = { "kind", "abbr", "menu" },
					format = function(entry, vim_item)
						local kind =
							require("lspkind").cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
						local strings = vim.split(kind.kind, "%s", { trimempty = true })
						kind.kind = " " .. (strings[1] or "") .. " "
						kind.menu = "    (" .. (strings[2] or "") .. ")"
						return kind
					end,
				},
				sources = {
					{ name = "nvim_lsp", priority = 1000 },
					-- { name = "minuet", priority = 100 }, -- Thêm minuet với priority cao
					{ name = "luasnip", priority = 750 },
					{ name = "buffer", priority = 500, keyword_length = 3, max_item_count = 5 },
					{ name = "path", priority = 250 },
				},
				performance = {
					debounce = 60,
					throttle = 30,
					fetching_timeout = 500,
					confirm_resolve_timeout = 80,
					async_budget = 1,
					max_view_entries = 200,
				},
				confirm_opts = {
					behavior = cmp.ConfirmBehavior.Replace,
					select = false,
				},
				window = {
					documentation = {
						border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
					},
					completion = {
						col_offset = -3,
						side_padding = 0,
						border = "rounded",
						winhighlight = "Normal:Normal,FloatBorder:BorderBG,CursorLine:PmenuSel,Search:None",
					},
				},
				experimental = {
					ghost_text = false,
					native_menu = false,
				},
			}
		end,
	},
}

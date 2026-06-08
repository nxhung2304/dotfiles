return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lua",
		},
		opts = function()
			local cmp = require("cmp")
			local mini_snippets = require("mini.snippets")
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
						local insert = mini_snippets.config.expand.insert or mini_snippets.default_insert
						insert({ body = args.body })
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
						elseif mini_snippets.session.get() ~= nil then
							mini_snippets.session.jump("next")
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif mini_snippets.session.get() ~= nil then
							mini_snippets.session.jump("prev")
						else
							fallback()
						end
					end, { "i", "s" }),
				},
				formatting = {
					fields = { "kind", "abbr", "menu" },
					format = function(_, vim_item)
						local icons = {
							Text = "󰉿", Method = "󰆧", Function = "󰊕", Constructor = "",
							Field = "󰜢", Variable = "󰀫", Class = "󰠱", Interface = "",
							Module = "", Property = "󰜢", Unit = "󰑭", Value = "󰎠",
							Enum = "", Keyword = "󰌋", Snippet = "", Color = "󰏘",
							File = "󰈙", Reference = "󰈇", Folder = "󰉋", EnumMember = "",
							Constant = "󰏿", Struct = "󰙅", Event = "", Operator = "󰆕",
							TypeParameter = "",
						}
						local kind_name = vim_item.kind or ""
						vim_item.kind = " " .. (icons[kind_name] or "󰉿") .. " "
						vim_item.menu = "    (" .. kind_name .. ")"
						if #vim_item.abbr > 50 then vim_item.abbr = vim_item.abbr:sub(1, 50) end
						return vim_item
					end,
				},
				sources = {
					{ name = "nvim_lsp", priority = 1000 },
					-- { name = "minuet", priority = 100 },
					{ name = "i18n",    priority = 900 },
					{ name = "buffer",  priority = 500, keyword_length = 3, max_item_count = 5 },
					{ name = "path",    priority = 250 },
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

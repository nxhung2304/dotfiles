local current_buffer_words_cache = { bufnr = nil, changedtick = nil, words = {} }

local function get_current_buffer_words()
	local bufnr = vim.api.nvim_get_current_buf()
	local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
	local cache = current_buffer_words_cache
	if cache.bufnr == bufnr and cache.changedtick == changedtick then
		return cache.words
	end

	local words = {}
	for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
		if #line < 5000 then
			for word in line:gmatch("[%a_][%w_]*[?!]?") do
				words[word] = true
			end
		end
	end

	cache.bufnr, cache.changedtick, cache.words = bufnr, changedtick, words
	return words
end

local function prefer_current_buffer_words(entry1, entry2)
	local words = get_current_buffer_words()
	local is_entry1_in_buffer = words[entry1.word] == true
	local is_entry2_in_buffer = words[entry2.word] == true
	if is_entry1_in_buffer ~= is_entry2_in_buffer then
		return is_entry1_in_buffer
	end
	return nil
end

return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-nvim-lsp-signature-help",
		},
		opts = function()
			local cmp = require("cmp")
			local mini_snippets = require("mini.snippets")

			-- Some LSP servers send `detail`/`documentation` as JSON null, which
			-- decodes to `vim.NIL` (userdata). nvim-cmp's `item.detail ~= ''` guard
			-- treats that as truthy and calls str.trim(vim.NIL) -> crash. Coerce any
			-- non-string passed to trim into "" so bad items degrade gracefully.
			local str = require("cmp.utils.str")
			if not str.__trim_guarded then
				local orig_trim = str.trim
				str.trim = function(text)
					if type(text) ~= "string" then
						return ""
					end
					return orig_trim(text)
				end
				str.__trim_guarded = true
			end
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
					-- Confirm only when an entry is actually selected; otherwise
					-- fall back so nvim-autopairs' <CR> (endwise / newline) runs.
					["<CR>"] = cmp.mapping(function(fallback)
						if cmp.visible() and cmp.get_active_entry() then
							cmp.confirm({ select = false })
						else
							fallback()
						end
					end, { "i", "s" }),
					["<Tab>"] = cmp.mapping(function(fallback)
						local ok, copilot = pcall(require, "copilot.suggestion")
						if cmp.visible() then
							cmp.select_next_item()
						elseif ok and copilot.is_visible() then
							copilot.accept()
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
					{ name = "nvim_lsp_signature_help", priority = 1200 },
					{ name = "nvim_lsp", priority = 1000 },
					-- { name = "minuet", priority = 100 },
					{ name = "i18n",    priority = 900 },
					{ name = "buffer",  priority = 500, keyword_length = 3, max_item_count = 5 },
					{ name = "path",    priority = 250 },
				},
				sorting = {
					priority_weight = 2,
					comparators = {
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						prefer_current_buffer_words,
						cmp.config.compare.score,
						cmp.config.compare.recently_used,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
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
						border = "rounded",
					},
					completion = {
						col_offset = -3,
						side_padding = 0,
						border = "rounded",
						winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
					},
				},
				experimental = {
					ghost_text = false,
					native_menu = false,
				},
			}
		end,
		config = function(_, opts)
			local cmp = require("cmp")
			cmp.setup(opts)
			require("rails-tools.integrations.cmp").setup()
			cmp.setup.filetype({ "ruby", "eruby" }, {
				sources = cmp.config.sources({
					{ name = "nvim_lsp_signature_help", priority = 1200 },
					{ name = "rails_schema", priority = 1100 },
					{ name = "nvim_lsp",     priority = 1000 },
					{ name = "buffer",       priority = 500, keyword_length = 3, max_item_count = 5 },
					{ name = "path",         priority = 250 },
				}),
			})
		end,
	},
}

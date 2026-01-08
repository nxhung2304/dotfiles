-- VTSLS configuration for Vue 3 support
local vue_language_server_path = vim.fn.stdpath("data")
	.. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

local vue_plugin = {
	name = "@vue/typescript-plugin",
	location = vue_language_server_path,
	languages = { "vue" },
	configNamespace = "typescript",
}

return {
	on_attach = function(client, bufnr)
		-- Disable semantic tokens for Vue files to let Volar handle them
		if vim.bo[bufnr].filetype == "vue" then
			client.server_capabilities.semanticTokensProvider = nil
		end

		-- Ensure completion capability is enabled for all file types
		client.server_capabilities.completionProvider = {
			resolveProvider = true,
			triggerCharacters = { ".", "/", "@", "<", '"', "'", "`", "$", "{" },
		}
	end,
	settings = {
		vtsls = {
			tsserver = {
				globalPlugins = {
					vue_plugin,
				},
			},
		},
	},
	filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
}

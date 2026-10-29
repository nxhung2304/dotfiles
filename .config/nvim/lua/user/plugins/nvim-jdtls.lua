return {
	"mfussenegger/nvim-jdtls",
	ft = "java",
	config = function()
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
		local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name

		local opts = {
			-- The command that starts the language server
			-- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
			cmd = {
				"jdtls",
				-- depends on if `java` is in your $PATH env variable and if it points to the right version.
				"-data",
				workspace_dir,
			},

			root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),

			-- Here you can configure eclipse.jdt.ls specific settings
			-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
			-- for a list of options
			settings = {
				java = {},
			},

			-- Language server `initializationOptions`
			-- You need to extend the `bundles` with paths to jar files
			-- if you want to use additional eclipse.jdt.ls plugins.
			--
			-- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
			--
			-- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
			init_options = {
				bundles = {},
			},

			on_attach = require("user.core.utils").lsp_on_attach,
			capabilities = require("cmp_nvim_lsp").default_capabilities(),
		}

		require("jdtls").start_or_attach(opts)
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("JdtlsAttach", { clear = true }),
			pattern = "java",
			callback = function(args)
				require("jdtls").start_or_attach(opts, nil, { bufnr = args.buf })
			end,
		})
	end,
}

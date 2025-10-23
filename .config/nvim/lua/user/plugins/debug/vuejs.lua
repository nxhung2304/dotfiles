local M = {}

M.config = function(dap)
	local dap_vscode_js = require("dap-vscode-js")

	dap_vscode_js.setup({
		adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
	})

	for _, language in ipairs({ "typescript", "javascript", "vue" }) do
		dap.configurations[language] = {
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				cwd = "${workspaceFolder}",
			},
			{
				type = "pwa-node",
				request = "attach",
				name = "Attach",
				processId = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
			},
		}
	end
end

return M

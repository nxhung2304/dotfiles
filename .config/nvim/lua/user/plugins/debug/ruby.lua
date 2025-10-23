local M = {}

M.config = function(dap)
	dap.configurations.ruby = {
		{
			type = "ruby",
			name = "Rails server",
			request = "attach",
			command = "bundle exec rails server",
			port = 38698,
		},
		{
			type = "ruby",
			name = "Minitest",
			request = "attach",
			script = "${file}",
			port = 38698,
		},
	}
end

return M

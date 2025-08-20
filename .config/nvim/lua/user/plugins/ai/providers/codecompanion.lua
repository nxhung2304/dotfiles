local M = {}

local model = "deepseek-coder:6.7b-instruct-q4_0"

function M.config()
	return {
		ollama = {
			schema = {
				model = {
					default = model,
				},
				temperature = 0.3,
				max_tokens = 4096,
				num_ctx = 8192,
			},
			env = {
				url = "http://localhost:11434", -- Chat endpoint
			},
		},
	}
end

return M

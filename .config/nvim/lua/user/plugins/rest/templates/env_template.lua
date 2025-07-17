-- templates/env_template.lua
local M = {}

M.render = [[
# REST Workspace Environment
base_url=https://jsonplaceholder.typicode.com
api_key=your_api_key_here
token=your_token_here

# Development Environment
dev_token=your_dev_token_here
dev_url=http://localhost:3000

# Staging Environment  
staging_token=your_staging_token_here
staging_url=https://staging.api.example.com

# Production Environment
prod_token=your_prod_token_here
prod_url=https://api.example.com

# OAuth
client_id=your_client_id
client_secret=your_client_secret
]]

return M

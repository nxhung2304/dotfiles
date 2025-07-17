local M = {}
local rest_layout_active = false

function M.toggle_rest_layout()
	local edgy = require("edgy")

	if rest_layout_active then
		edgy.close("right")
		edgy.close("bottom")
		rest_layout_active = false
		vim.notify("Rest layout closed", vim.log.levels.INFO)
	else
		-- Mở result pane trước
		vim.cmd("Rest open")
		-- Hoặc có thể dùng:
		-- edgy.open("right")
		-- edgy.open("bottom")
		rest_layout_active = true
		vim.notify("Rest layout opened", vim.log.levels.INFO)
	end
end

-- Auto setup khi mở file .http

-- 	pattern = "http",
-- 	callback = function()
-- 		-- Delay một chút để đảm bảo everything loaded
-- 		vim.defer_fn(function()
-- 			if not rest_layout_active then
-- 				M.toggle_rest_layout()
-- 			end
-- 		end, 100)
-- 	end,
-- })
--
-- -- Auto đóng khi không còn file .http
-- vim.api.nvim_create_autocmd("BufLeave", {
-- 	pattern = "*.http",
-- 	callback = function()
-- 		vim.defer_fn(function()
-- 			local http_buffers = vim.tbl_filter(function(buf)
-- 				return vim.bo[buf].filetype == "http" and vim.api.nvim_buf_is_loaded(buf)
-- 			end, vim.api.nvim_list_bufs())
--
-- 			if #http_buffers == 0 and rest_layout_active then
-- 				M.toggle_rest_layout()
-- 			end
-- 		end, 100)
-- 	end,
-- })

return M

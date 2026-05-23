return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup()
		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end, { desc = "Add file to harpoon" })
		vim.keymap.set("n", "<C-e>", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end)
		vim.keymap.set("n", "<C-p>", function()
			harpoon:list():prev()
		end)
		vim.keymap.set("n", "<C-n>", function()
			harpoon:list():next()
		end)
		vim.keymap.set("n", "<leader>sl", function()
			local file_paths = {}
			for _, item in ipairs(harpoon:list().items) do
				table.insert(file_paths, { file = item.value, text = item.value })
			end
			require("snacks").picker.pick({
				title = "Working List",
				items = file_paths,
				format = "file",
				preview = "file",
				confirm = function(picker, item)
					picker:close()
					if item then
						vim.cmd("edit " .. item.file)
					end
				end,
			})
		end, { desc = "Open harpoon window" })
	end,
}

local M = {}

local function pascal_case(snake_name)
	local parts = {}
	for part in snake_name:gmatch("[^_]+") do
		table.insert(parts, part:sub(1, 1):upper() .. part:sub(2))
	end
	return table.concat(parts)
end

local function find_class_declaration(file_path, class_name)
	for lnum, line in ipairs(vim.fn.readfile(file_path)) do
		local s = line:find("class%s+" .. class_name .. "[%s<{]")
		if s then
			local name_col = line:find(class_name, s, true)
			return lnum, name_col - 1
		end
	end
	return nil
end

local SIDEBAR_FILETYPES = {
	NvimTree = true,
	["neo-tree"] = true,
	oil = true,
}

local function open_file_for_edit(path)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.api.nvim_win_get_config(win).relative == "" and not SIDEBAR_FILETYPES[vim.bo[buf].filetype] then
			vim.api.nvim_set_current_win(win)
			vim.cmd("edit " .. vim.fn.fnameescape(path))
			return
		end
	end
	vim.cmd("vsplit " .. vim.fn.fnameescape(path))
end

function M.maybe_rename_class(destination, old_basename, new_basename, after)
	after = after or function() end
	local old_class = pascal_case(old_basename)
	local new_class = pascal_case(new_basename)
	if old_class == new_class then
		after()
		return
	end

	local lnum, col = find_class_declaration(destination, old_class)
	if not lnum then
		after()
		return
	end

	vim.ui.select({ "Yes", "No" }, {
		prompt = ("Rename class %s -> %s?"):format(old_class, new_class),
	}, function(choice)
		if choice ~= "Yes" then
			after()
			return
		end

		open_file_for_edit(destination)
		vim.api.nvim_win_set_cursor(0, { lnum, col })

		local function do_rename()
			vim.lsp.buf.rename(new_class)
			after()
		end

		if #vim.lsp.get_clients({ bufnr = 0, name = "dartls" }) > 0 then
			do_rename()
		else
			vim.api.nvim_create_autocmd("LspAttach", {
				once = true,
				buffer = 0,
				callback = vim.schedule_wrap(do_rename),
			})
		end
	end)
end

function M.notify_dartls_rename(source, destination, callback)
	local dartls_client = vim.lsp.get_clients({ name = "dartls" })[1]
	if not dartls_client then
		callback()
		return
	end

	local params = {
		files = { {
			oldUri = vim.uri_from_fname(source),
			newUri = vim.uri_from_fname(destination),
		} },
	}

	dartls_client:request("workspace/willRenameFiles", params, function(err, result)
		if err then
			vim.notify(err.message or "dartls willRenameFiles failed", vim.log.levels.WARN)
		elseif result then
			vim.lsp.util.apply_workspace_edit(result, dartls_client.offset_encoding)
		end
		callback()
	end)
end

function M.rename_nvim_tree_node(node, fallback)
	if vim.fn.fnamemodify(node.absolute_path, ":e") ~= "dart" then
		fallback()
		return
	end

	vim.ui.input({ prompt = "Rename to ", default = node.name }, function(new_name)
		if not new_name or new_name == "" or new_name == node.name then
			return
		end

		local source = node.absolute_path
		local destination = vim.fs.joinpath(vim.fs.dirname(source), new_name)

		M.notify_dartls_rename(source, destination, function()
			require("nvim-tree.actions.fs.rename-file").rename(node, destination)
			local api = require("nvim-tree.api")
			api.tree.reload()
			api.tree.find_file({ buf = destination })

			M.maybe_rename_class(destination, vim.fn.fnamemodify(node.name, ":r"), vim.fn.fnamemodify(new_name, ":r"))
		end)
	end)
end

function M.setup_neo_tree_rename_hook()
	local ok, events = pcall(require, "neo-tree.events")
	if not ok then
		return
	end

	events.subscribe({
		event = events.BEFORE_FILE_RENAME,
		handler = function(args)
			if vim.fn.fnamemodify(args.destination, ":e") ~= "dart" then
				return
			end
			M.notify_dartls_rename(args.source, args.destination, args.callback)
			return { handled = true }
		end,
	})

	events.subscribe({
		event = events.FILE_RENAMED,
		handler = function(args)
			if vim.fn.fnamemodify(args.destination, ":e") ~= "dart" then
				return
			end
			M.maybe_rename_class(
				args.destination,
				vim.fn.fnamemodify(args.source, ":t:r"),
				vim.fn.fnamemodify(args.destination, ":t:r")
			)
		end,
	})
end

function M.setup_oil_rename_hook()
	vim.api.nvim_create_autocmd("User", {
		pattern = "OilActionsPost",
		callback = function(ev)
			for _, action in ipairs(ev.data.actions) do
				if action.type == "move" then
					local oil_util = require("oil.util")
					local oil_fs = require("oil.fs")
					local _, src_path = oil_util.parse_url(action.src_url)
					local _, dest_path = oil_util.parse_url(action.dest_url)
					local destination = oil_fs.posix_to_os_path(dest_path)

					if vim.fn.fnamemodify(destination, ":e") == "dart" then
						M.maybe_rename_class(
							destination,
							vim.fn.fnamemodify(oil_fs.posix_to_os_path(src_path), ":t:r"),
							vim.fn.fnamemodify(destination, ":t:r")
						)
					end
				end
			end
		end,
	})
end

function M.create_or_open_test_file()
	local current_file = vim.fn.expand("%:p")
	local current_filetype = vim.bo.filetype

	if current_filetype ~= "dart" then
		print("Error: Please open a Dart file first")
		return
	end

	local workspace_folder = vim.fn.getcwd()
	local relative_path = vim.fn.fnamemodify(current_file, ":.")
	local file_name = vim.fn.fnamemodify(current_file, ":t:r")

	if file_name:match("_test$") then
		print("Already in a test file: " .. relative_path)
		return
	end

	if relative_path:match("^test/") then
		print("Already in test directory: " .. relative_path)
		return
	end

	local class_name = file_name:gsub("^%l", string.upper) -- Capitalize first letter

	local test_file_path

	if relative_path:match("^lib/") then
		local lib_path = relative_path:gsub("^lib/", "")
		local dir_path = lib_path:gsub("/[^/]*$", "")
		local test_filename = file_name .. "_test.dart"

		if dir_path == lib_path then
			test_file_path = workspace_folder .. "/test/" .. test_filename
		else
			test_file_path = workspace_folder .. "/test/" .. dir_path .. "/" .. test_filename
		end
	else
		test_file_path = workspace_folder .. "/test/" .. file_name .. "_test.dart"
	end

	if vim.fn.filereadable(test_file_path) == 1 then
		vim.cmd("edit " .. test_file_path)
		print("Opened existing test file: " .. vim.fn.fnamemodify(test_file_path, ":."))
	else
		local test_relative = test_file_path:gsub(workspace_folder .. "/", "")
		local depth = select(2, test_relative:gsub("/", "")) - 1
		local helper_path = string.rep("../", depth) .. "helpers/test_helper.dart"

		local test_dir = vim.fn.fnamemodify(test_file_path, ":h")
		vim.fn.mkdir(test_dir, "p")

		local template = string.format(
			[[import 'package:flutter_test/flutter_test.dart';

void main() {
setUp(() {

});
tearDownAll(() {
  TestHelper.tearDownTestEnvironment();
});
group('%s Test', () {
  

});
}]],
			helper_path,
			class_name
		)

		local file = io.open(test_file_path, "w")
		if file then
			file:write(template)
			file:close()
			vim.cmd("edit " .. test_file_path)
			print("Created new test file: " .. vim.fn.fnamemodify(test_file_path, ":."))

			vim.schedule(function()
				vim.fn.search("group.*Test.*{")
				vim.cmd("normal! o")
				vim.cmd("startinsert")
			end)
		else
			print("Error: Could not create test file")
		end
	end
end

return M

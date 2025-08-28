local M = {}

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

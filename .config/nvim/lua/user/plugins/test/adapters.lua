-- Test framework adapters.
--
-- Each adapter describes how to run and parse tests for one framework so the
-- generic runner (runner.lua) stays framework-agnostic. To add a framework,
-- append an entry to `M.adapters` implementing the fields documented below.
--
-- Adapter fields:
--   name            string            display / debug name
--   detect_file()   -> bool           true when the CURRENT buffer is a test
--                                      file for this framework
--   detect_project()-> bool           true when the project (cwd upward) uses
--                                      this framework (for "run all")
--   nearest()       -> cmd, label     command + label for the test at cursor
--   file()          -> cmd, label     command + label for the current file
--   all()           -> cmd, label     command + label for the whole suite
--   loc_patterns    { lua_pattern }   patterns capturing (file, lnum) from
--                                      output, used for jump-to-error & qflist
--   failure_markers { lua_pattern }   line patterns marking a failure, used by
--                                      ]f / [f navigation
--   summary(text)   -> count|nil      number of failures parsed from output

local M = {}

-- Search from the current file upward for a marker file/dir.
local function has_up(name, kind)
	local found = kind == "dir" and vim.fn.finddir(name, ".;") or vim.fn.findfile(name, ".;")
	return found ~= nil and found ~= ""
end

local function cur_file()
	return vim.fn.expand("%:p")
end

local function rel_file()
	return vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
end

local function cur_line()
	return vim.fn.line(".")
end

--------------------------------------------------------------------------------
-- Rails / minitest
--------------------------------------------------------------------------------
local rails = {
	name = "rails",
	detect_file = function()
		return vim.bo.filetype == "ruby"
			and (vim.fn.expand("%:t"):match("_test%.rb$") ~= nil or vim.fn.expand("%:p"):match("/test/") ~= nil)
	end,
	detect_project = function()
		return has_up("Gemfile") and has_up("test", "dir")
	end,
	nearest = function()
		return "bundle exec rails test " .. cur_file() .. ":" .. cur_line(), rel_file() .. ":" .. cur_line()
	end,
	file = function()
		return "bundle exec rails test " .. cur_file(), rel_file()
	end,
	all = function()
		return "bundle exec rails test", "rails test"
	end,
	loc_patterns = { "%[([^%]]+):(%d+)%]:" },
	failure_markers = { "^Failure:", "^Error:" },
	summary = function(text)
		local f, e = text:match("(%d+) failures?, (%d+) errors?")
		if f then
			return tonumber(f) + tonumber(e)
		end
	end,
}

--------------------------------------------------------------------------------
-- RSpec
--------------------------------------------------------------------------------
local rspec = {
	name = "rspec",
	detect_file = function()
		return vim.bo.filetype == "ruby"
			and (vim.fn.expand("%:t"):match("_spec%.rb$") ~= nil or vim.fn.expand("%:p"):match("/spec/") ~= nil)
	end,
	detect_project = function()
		return has_up("Gemfile") and has_up("spec", "dir")
	end,
	nearest = function()
		return "bundle exec rspec " .. cur_file() .. ":" .. cur_line(), rel_file() .. ":" .. cur_line()
	end,
	file = function()
		return "bundle exec rspec " .. cur_file(), rel_file()
	end,
	all = function()
		return "bundle exec rspec", "rspec"
	end,
	loc_patterns = { "rspec (%S+%.rb):(%d+)", "# ?(%.?/?[%w%._%-/]+%.rb):(%d+)" },
	failure_markers = { "Failure/Error:", "^rspec %./" },
	summary = function(text)
		local _, f = text:match("(%d+) examples?, (%d+) failures?")
		if f then
			return tonumber(f)
		end
	end,
}

--------------------------------------------------------------------------------
-- Flutter / Dart
--------------------------------------------------------------------------------
-- Walk up from the cursor to find the enclosing test/testWidgets/group name so
-- we can run a single test via `--plain-name` (Flutter has no line targeting).
local function dart_nearest_name()
	local lnum = vim.fn.line(".")
	for i = lnum, 1, -1 do
		local line = vim.fn.getline(i)
		local name = line:match("test%w*%s*%(%s*['\"]([^'\"]+)['\"]")
			or line:match("group%s*%(%s*['\"]([^'\"]+)['\"]")
		if name then
			return name
		end
	end
end

local flutter = {
	name = "flutter",
	detect_file = function()
		return vim.bo.filetype == "dart" and has_up("pubspec.yaml")
	end,
	detect_project = function()
		return has_up("pubspec.yaml")
	end,
	nearest = function()
		local name = dart_nearest_name()
		if not name then
			vim.notify("No enclosing test found — running file", vim.log.levels.INFO)
			return "flutter test " .. cur_file(), rel_file()
		end
		local escaped = name:gsub("'", "'\\''")
		return "flutter test " .. cur_file() .. " --plain-name '" .. escaped .. "'", rel_file() .. " › " .. name
	end,
	file = function()
		return "flutter test " .. cur_file(), rel_file()
	end,
	all = function()
		return "flutter test", "flutter test"
	end,
	loc_patterns = {
		"([%w%._%-/]+%.dart):(%d+):%d+",
		"([%w%._%-/]+%.dart) (%d+):%d+",
		"([%w%._%-/]+%.dart):(%d+)",
	},
	failure_markers = { "Expected:", "^%s*Actual:", "Some tests failed" },
	summary = function(text)
		local f = text:match("%+%d+%s+%-(%d+)")
		if f then
			return tonumber(f)
		end
	end,
}

-- Order matters: more specific test-file detectors first (rspec/rails share the
-- ruby filetype but differ by spec/ vs test/).
M.adapters = { rspec, rails, flutter }

-- Pick the adapter for the current buffer, falling back to project detection so
-- "run all" works even when the active buffer is not a test file.
function M.pick()
	for _, a in ipairs(M.adapters) do
		if a.detect_file() then
			return a
		end
	end
	for _, a in ipairs(M.adapters) do
		if a.detect_project() then
			return a
		end
	end
end

return M

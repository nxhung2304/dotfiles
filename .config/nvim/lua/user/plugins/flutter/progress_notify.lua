local M = {}

local LISTENER_KEY = "flutter_progress_notify"
local HOT_RELOAD_FAILURE_PATTERN = "^Failed to Hot %a+:"
local NOTIFICATION_TITLE = "Flutter"

local progress_spinners = {}

local function progress_label(body)
	local message = body.message or body.title or NOTIFICATION_TITLE
	local without_ellipsis = message:gsub("…$", "")
	local without_dots = without_ellipsis:gsub("%.%.%.$", "")
	return without_dots
end

local function stop_progress_spinner(progress_id)
	local spinner = progress_spinners[progress_id]
	if not spinner then
		return
	end

	spinner.stop()
	progress_spinners[progress_id] = nil
end

local function stop_all_progress_spinners()
	for progress_id in pairs(progress_spinners) do
		stop_progress_spinner(progress_id)
	end
end

local function is_dart_session(session)
	return session.config.type == "dart"
end

local function silence_flutter_tools_progress()
	-- flutter-tools' cmdline progress covers the statusline (cmdheight=0).
	-- Progress is shown via start_spinner instead.
	require("flutter-tools.ui").progress = function()
		return { report = function() end }
	end
end

local function notify_hot_reload_failure(session, body)
	local is_console_output = body.category == "console" and body.output ~= nil
	if not is_dart_session(session) or not is_console_output then
		return
	end

	-- Text comes from the Flutter debug adapter's console output, not an API.
	-- Update the pattern if Flutter changes it.
	if body.output:match(HOT_RELOAD_FAILURE_PATTERN) then
		vim.notify(vim.trim(body.output), vim.log.levels.ERROR, { title = NOTIFICATION_TITLE })
	end
end

function M.setup(start_spinner)
	silence_flutter_tools_progress()

	local dap = require("dap")
	dap.listeners.before.event_progressStart[LISTENER_KEY] = function(session, body)
		if not is_dart_session(session) then
			return
		end

		stop_progress_spinner(body.progressId)
		local stop, set_label = start_spinner(progress_label(body))
		progress_spinners[body.progressId] = { stop = stop, set_label = set_label }
	end
	dap.listeners.before.event_progressUpdate[LISTENER_KEY] = function(_, body)
		local spinner = progress_spinners[body.progressId]
		if spinner and body.message then
			spinner.set_label(progress_label(body))
		end
	end
	dap.listeners.before.event_progressEnd[LISTENER_KEY] = function(_, body)
		stop_progress_spinner(body.progressId)
	end
	dap.listeners.before.event_terminated[LISTENER_KEY] = stop_all_progress_spinners
	dap.listeners.before.event_exited[LISTENER_KEY] = stop_all_progress_spinners
	dap.listeners.after.event_output[LISTENER_KEY] = notify_hot_reload_failure
end

return M

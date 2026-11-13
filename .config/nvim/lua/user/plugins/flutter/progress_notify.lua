local M = {}

local LISTENER_KEY = "flutter_progress_notify"
local HOT_RELOAD_FAILURE_PATTERN = "^Failed to Hot %a+:"
local NOTIFICATION_TITLE = "Flutter"
local DISCONNECT_TITLE = "Device disconnected"
local DISCONNECT_MESSAGE = "Flutter lost the connection. Check the cable or Wi-Fi, then run again."
local DISCONNECT_ICON = "󰖪"
local UNKNOWN_DEVICE_NAME = "Unknown device"
local SYSTEM_NOTIFIER = "terminal-notifier"
local SYSTEM_NOTIFIER_SOUND = "Basso"
local SYSTEM_NOTIFIER_GROUP = "flutter-disconnect"
local SYSTEM_NOTIFIER_MISSING_MESSAGE = "terminal-notifier is not installed, no system notification sent"
local SYSTEM_NOTIFIER_FAILED_MESSAGE = "terminal-notifier failed: "

local progress_spinners = {}
local stop_requested_by_user = false
local disconnect_reported = false

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

local function current_device_name()
	local ok, commands = pcall(require, "flutter-tools.commands")
	local device = ok and commands.current_device()
	return device and device.name or UNKNOWN_DEVICE_NAME
end

local function send_system_notification(device_name)
	if vim.fn.executable(SYSTEM_NOTIFIER) == 0 then
		vim.notify(SYSTEM_NOTIFIER_MISSING_MESSAGE, vim.log.levels.WARN, { title = NOTIFICATION_TITLE })
		return
	end

	local command = {
		SYSTEM_NOTIFIER,
		"-title",
		NOTIFICATION_TITLE,
		"-subtitle",
		device_name,
		"-message",
		DISCONNECT_MESSAGE,
		"-sound",
		SYSTEM_NOTIFIER_SOUND,
		"-group",
		SYSTEM_NOTIFIER_GROUP,
	}
	vim.system(command, {}, function(result)
		if result.code == 0 then
			return
		end
		vim.schedule(function()
			vim.notify(
				SYSTEM_NOTIFIER_FAILED_MESSAGE .. (result.stderr or ""),
				vim.log.levels.WARN,
				{ title = NOTIFICATION_TITLE }
			)
		end)
	end)
end

local function report_device_disconnected(session)
	if not is_dart_session(session) then
		return
	end

	vim.notify("[DEBUG-disconnect] session ended, user_stop=" .. tostring(stop_requested_by_user), vim.log.levels.INFO)
	if stop_requested_by_user or disconnect_reported then
		return
	end

	disconnect_reported = true
	local device_name = current_device_name()
	vim.notify(device_name .. "\n" .. DISCONNECT_MESSAGE, vim.log.levels.ERROR, {
		title = DISCONNECT_TITLE,
		icon = DISCONNECT_ICON,
		timeout = false,
	})
	send_system_notification(device_name)
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
	dap.listeners.after.event_initialized[LISTENER_KEY] = function()
		stop_requested_by_user = false
		disconnect_reported = false
	end
	dap.listeners.before.disconnect[LISTENER_KEY] = function()
		stop_requested_by_user = true
	end
	dap.listeners.before.terminate[LISTENER_KEY] = function()
		stop_requested_by_user = true
	end
	dap.listeners.before.event_terminated[LISTENER_KEY] = function(session)
		stop_all_progress_spinners()
		report_device_disconnected(session)
	end
	dap.listeners.before.event_exited[LISTENER_KEY] = function(session)
		stop_all_progress_spinners()
		report_device_disconnected(session)
	end
	dap.listeners.after.event_output[LISTENER_KEY] = notify_hot_reload_failure
end

return M

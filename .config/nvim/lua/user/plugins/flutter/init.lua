return {
  {
    "Weissle/persistent-breakpoints.nvim",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      require("persistent-breakpoints").setup({ load_breakpoints_event = { "BufReadPost" } })
    end,
  },
  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
      "mfussenegger/nvim-dap",
      "theHamsta/nvim-dap-virtual-text",
      "igorlfs/nvim-dap-view",
    },
    config = function()
      require("flutter-tools").setup({
        ui = { border = "rounded" },

        decorations = {
          statusline = {
            app_version = true,
            device = true,
            project_config = true,
          },
        },

        dev_log = {
          enabled = true,
          notify_errors = true,
          -- Window is auto-closed by autocmd below; buffer stays alive for tmux sync
          open_cmd = "botright 1split",
          focus_on_open = false,
        },

        widget_guides = { enabled = true },

        closing_tags = {
          enabled = true,
          highlight = "Comment",
          prefix = "  ",
        },

        debugger = {
          enabled = true,
          run_via_dap = true,
          exception_breakpoints = {},
          evaluate_to_string_in_debug_views = true,
        },

        lsp = {
          on_attach = require("user.core.utils").lsp_on_attach,
          capabilities = require("cmp_nvim_lsp").default_capabilities(),
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            updateImportsOnRename = true,
            renameFilesWithClasses = "prompt",
            enableSnippets = true,
            analysisExcludedFolders = {
              vim.fn.expand("$HOME/.pub-cache"),
              vim.fn.expand("~/flutter"),
            },
          },
        },
      })

      require("nvim-dap-virtual-text").setup({
        enabled = true,
        highlight_changed_variables = true,
        show_stop_reason = true,
        all_frames = true,
      })

      require("dap-view").setup({
        winbar = {
          show = true,
          sections = { "scopes", "repl" },
          default_section = "scopes",
          controls = { enabled = true, position = "right" },
        },
        windows = { size = 0.35, position = "left" },
      })

      local dap = require("dap")
      local dap_view = require("dap-view")

      -- `debugPC` (the stopped-line highlight) is unstyled in most colorschemes,
      -- so the sign shows but the line itself isn't highlighted. Use a fixed
      -- amber tint (independent of the active colorscheme) so the stopped
      -- line always stands out, and reapply on every theme switch.
      local function set_debug_hl()
        vim.api.nvim_set_hl(0, "debugPC", { bg = "#4d3319" })
      end
      set_debug_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_debug_hl })

      -- Close REPL when debug session ends; don't auto-open (toggle manually)
      dap.listeners.before.event_terminated["flutter_repl"] = function()
        dap.repl.close()
      end

      -- Keep the REPL for variable/expression evaluation only; stdout/stderr
      -- (Flutter's print/log output) is already viewable in the tmux pane.
      dap.defaults.fallback.on_output = function(_, body)
        if body.category == "stdout" or body.category == "stderr" then
          return
        end
        dap.repl.append(body.output, "$", { newline = false })
      end

      -- Always focus the source window when execution stops (breakpoint/step),
      -- even if focus was in dap-repl/dap-view at the time.
      dap.listeners.after.event_stopped["flutter_focus_source"] = function(session)
        vim.schedule(function()
          local frame = session.current_frame
          if not (frame and frame.source and frame.source.path) then return end
          local bufnr = vim.fn.bufnr(frame.source.path)
          if bufnr == -1 then return end
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == bufnr then
              vim.api.nvim_set_current_win(win)
              return
            end
          end
        end)
      end

      -- Flutter dev_log → tmux pane
      -- Sync __FLUTTER_DEV_LOG__ buffer to a file so tmux can tail -f it
      local flutter_log_path = vim.fn.stdpath("cache") .. "/flutter_dev.log"
      local flutter_log_attached = {}  -- keyed by bufnr

      local function watch_flutter_log(bufnr)
        if flutter_log_attached[bufnr] then return end
        flutter_log_attached[bufnr] = true
        -- Write any existing content first
        local existing = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if #existing > 0 then
          vim.fn.writefile(existing, flutter_log_path)
        end
        vim.api.nvim_buf_attach(bufnr, false, {
          -- Append only new lines so tail -f tracks correctly
          on_lines = function(_, buf, _, _, last, new_last)
            if new_last > last then
              local new_lines = vim.api.nvim_buf_get_lines(buf, last, new_last, false)
              vim.fn.writefile(new_lines, flutter_log_path, "a")
            end
          end,
          on_detach = function() flutter_log_attached[bufnr] = nil end,
        })
      end

      -- BufAdd misses unlisted buffers (flutter-tools uses nvim_create_buf false/true),
      -- so rely on BufWinEnter which always fires when open_cmd runs.
      vim.api.nvim_create_autocmd("BufWinEnter", {
        pattern = "__FLUTTER_DEV_LOG__",
        callback = function(ev)
          watch_flutter_log(ev.buf)
          vim.schedule(function()
            local win = vim.fn.bufwinid(ev.buf)
            if win ~= -1 then pcall(vim.api.nvim_win_close, win, false) end
          end)
        end,
      })

      -- Open (or focus) the tmux window that tails the flutter dev log.
      -- Reuse existing window named flutter-log; open new one only if absent.
      local function open_flutter_log_window()
        if vim.fn.filereadable(flutter_log_path) == 0 then
          vim.fn.writefile({}, flutter_log_path)
        end
        local existing = vim.fn.system("tmux select-window -t flutter-log 2>&1")
        if existing:find("no window named") or existing:find("can't find") or existing:find("error") then
          vim.fn.system("tmux new-window -n 'flutter-log' 'tail -f " .. flutter_log_path .. "'")
        end
      end

      -- Wipe flutter-tools' dev_log buffer, the mirrored log file, and (if the
      -- tmux window already exists) the pane's scrollback, so leftover output
      -- from a previous session never bleeds into the next one.
      local function clear_flutter_log()
        vim.cmd("FlutterLogClear")
        vim.fn.writefile({}, flutter_log_path)
        local tail_cmd = "clear && tail -f " .. flutter_log_path
        vim.fn.system("tmux respawn-pane -t flutter-log -k '" .. tail_cmd .. "' 2>/dev/null")
      end

      -- Auto-pick a default device on project open: prefer a real, physically
      -- connected device; fall back to a simulator/emulator if none is plugged in.
      -- flutter-tools only tracks "current device" once a run session starts, so
      -- we cache our own pick and (a) surface it via vim.g.flutter_preferred_device
      -- for the statusline, (b) feed it into <leader>Fr/<leader>FD below.
      local preferred_device = nil

      local function is_virtual_device(device)
        local system = (device.system or ""):lower()
        local id = device.id or ""
        return system:find("simulator", 1, true)
          or system:find("emulator", 1, true)
          or id:match("^emulator%-") ~= nil
      end

      local function detect_preferred_device()
        local executable = require("flutter-tools.executable")
        local devices_mod = require("flutter-tools.devices")
        local Job = require("plenary.job")
        executable.flutter(function(cmd)
          local job = Job:new({
            command = cmd,
            args = { "devices" },
          })
          job:after_success(vim.schedule_wrap(function(j)
            local entries = devices_mod.to_selection_entries(j:result())
            local real, virtual
            for _, entry in ipairs(entries) do
              if entry.data then
                if is_virtual_device(entry.data) then
                  virtual = virtual or entry.data
                else
                  real = real or entry.data
                end
              end
            end
            preferred_device = real or virtual
            if preferred_device then
              vim.g.flutter_preferred_device = preferred_device.name
              vim.notify("Default device: " .. preferred_device.name, vim.log.levels.INFO, { title = "Flutter" })
            end
          end))
          job:start()
        end)
      end

      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          if vim.fs.find("pubspec.yaml", { upward = true, path = vim.fn.getcwd() })[1] then
            vim.defer_fn(detect_preferred_device, 300)
          end
        end,
      })

      -- Start an animated "<spinner> label…" notification; returns a stop() function
      -- that dismisses it. Safe to call stop() more than once.
      local function start_spinner(label)
        local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        local frame = 1
        local id = "flutter_loading_" .. label

        local timer = vim.uv.new_timer()
        timer:start(0, 80, vim.schedule_wrap(function()
          frame = frame % #frames + 1
          vim.notify(frames[frame] .. " " .. label .. "…", vim.log.levels.INFO, {
            id = id, title = "Flutter", timeout = false,
          })
        end))

        local stopped = false
        return function()
          if stopped then return end
          stopped = true
          if not timer:is_closing() then
            timer:stop()
            timer:close()
          end
          -- Dismiss the persistent notification (timeout=false won't self-close)
          vim.notify("", vim.log.levels.INFO, { id = id, timeout = 1 })
        end
      end

      local function run_or_debug(force_debug)
        local commands = require("flutter-tools.commands")
        clear_flutter_log()
        open_flutter_log_window()

        -- Spin until the app is actually running: debugger_runner emits
        -- FlutterToolsAppStarted on the DAP `app.started` event (i.e. once
        -- Flutter reports the app is live), not merely once the process spawns.
        local stop = start_spinner("Flutter running")
        local once = vim.api.nvim_create_autocmd("User", {
          pattern = "FlutterToolsAppStarted",
          once = true,
          callback = stop,
        })
        dap.listeners.before.event_terminated["flutter_loading"] = stop
        dap.listeners.before.event_exited["flutter_loading"] = stop
        vim.defer_fn(function()
          pcall(vim.api.nvim_del_autocmd, once)
          stop()
        end, 120000)

        if not commands.current_device() and preferred_device then
          commands.run({ device = preferred_device, force_debug = force_debug })
        else
          commands.run_command(nil, force_debug)
        end
      end

      -- Show spinner notification while FlutterDevices / FlutterEmulators load.
      -- Stops when the picker window opens (FileType autocmd) or after 8s fallback.
      local function flutter_with_loading(label, cmd)
        local stop = start_spinner(label)

        -- Hook vim.ui.select — flutter-tools always calls this regardless of UI backend
        local orig_select = vim.ui.select
        vim.ui.select = function(...)
          vim.ui.select = orig_select
          stop()
          return orig_select(...)
        end

        vim.defer_fn(function()
          vim.ui.select = orig_select
          stop()
        end, 8000)

        vim.cmd(cmd)
      end

      -- which-key group labels
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { "<leader>F", group = "Flutter" },
          { "<leader>d", group = "Debug" },
        })
      end

      -- Flutter commands (<leader>F)
      vim.keymap.set("n", "<leader>Fr", function() run_or_debug(false) end, { desc = "Flutter: Run" })
      vim.keymap.set("n", "<leader>FD", function() run_or_debug(true) end,  { desc = "Flutter: Debug" })
      vim.keymap.set("n", "<leader>Fs", "<cmd>FlutterRestart<CR>",       { desc = "Flutter: Hot Restart" })
      vim.keymap.set("n", "<leader>FR", "<cmd>FlutterReload<CR>",        { desc = "Flutter: Hot Reload" })
      vim.keymap.set("n", "<leader>Fq", "<cmd>FlutterQuit<CR>",          { desc = "Flutter: Quit" })
      vim.keymap.set("n", "<leader>Fl", open_flutter_log_window, { desc = "Flutter: Log in tmux pane" })
      vim.keymap.set("n", "<leader>FL", clear_flutter_log, { desc = "Flutter: Clear Log" })
      vim.keymap.set("n", "<leader>Fd", function()
        flutter_with_loading("Loading devices", "FlutterDevices")
      end, { desc = "Flutter: Devices" })
      vim.keymap.set("n", "<leader>Fe", function()
        flutter_with_loading("Loading emulators", "FlutterEmulators")
      end, { desc = "Flutter: Emulators" })
      vim.keymap.set("n", "<leader>Fo", "<cmd>FlutterOutlineToggle<CR>", { desc = "Flutter: Widget Outline" })
      vim.keymap.set("n", "<leader>Fp", "<cmd>FlutterPubGet<CR>",        { desc = "Flutter: Pub Get" })
      vim.keymap.set("n", "<leader>FP", "<cmd>FlutterPubUpgrade<CR>",    { desc = "Flutter: Pub Upgrade" })
      vim.keymap.set("n", "<leader>Fv", "<cmd>FlutterVisualDebug<CR>",   { desc = "Flutter: Visual Debug" })

      -- DAP controls (<leader>d)
      vim.keymap.set("n", "<leader>dc", dap.continue,          { desc = "Debug: Continue" })
      vim.keymap.set("n", "<leader>do", dap.step_over,         { desc = "Debug: Step Over" })
      vim.keymap.set("n", "<leader>di", dap.step_into,         { desc = "Debug: Step Into" })
      vim.keymap.set("n", "<leader>dO", dap.step_out,          { desc = "Debug: Step Out" })
      vim.keymap.set("n", "<leader>dt", dap.terminate,         { desc = "Debug: Terminate" })
      vim.keymap.set("n", "<leader>dl", function()
        local cmd = "botright " .. math.floor(vim.o.columns * 0.3) .. "vsplit"
        dap.repl.toggle({}, cmd)
      end, { desc = "Debug: Toggle REPL" })
      vim.keymap.set("n", "<leader>dv", dap_view.toggle,       { desc = "Debug: Toggle Panel" })
      local pb = require("persistent-breakpoints.api")
      vim.keymap.set("n", "<leader>db", pb.toggle_breakpoint,              { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>dB", pb.set_conditional_breakpoint,     { desc = "Debug: Conditional Breakpoint" })
      vim.keymap.set("n", "<leader>dC", pb.clear_all_breakpoints,          { desc = "Debug: Clear All Breakpoints" })
    end,
  },
}

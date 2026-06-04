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
          controls = { enabled = true, position = "right" },
        },
        windows = { size = 0.35, position = "left" },
      })

      local dap = require("dap")
      local dap_view = require("dap-view")

      -- Close REPL when debug session ends; don't auto-open (toggle manually)
      dap.listeners.before.event_terminated["flutter_repl"] = function()
        dap.repl.close()
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

      -- Show spinner notification while FlutterDevices / FlutterEmulators load.
      -- Stops when the picker window opens (FileType autocmd) or after 8s fallback.
      local function flutter_with_loading(label, cmd)
        local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        local frame = 1
        local id = "flutter_loading_" .. cmd

        local timer = vim.uv.new_timer()
        timer:start(0, 80, vim.schedule_wrap(function()
          frame = frame % #frames + 1
          vim.notify(frames[frame] .. " " .. label .. "…", vim.log.levels.INFO, {
            id = id, title = "Flutter", timeout = false,
          })
        end))

        local stopped = false
        local function stop()
          if stopped then return end
          stopped = true
          if not timer:is_closing() then
            timer:stop()
            timer:close()
          end
          -- Dismiss the persistent notification (timeout=false won't self-close)
          vim.notify("", vim.log.levels.INFO, { id = id, timeout = 1 })
        end

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
      vim.keymap.set("n", "<leader>Fr", "<cmd>FlutterRun<CR>",           { desc = "Flutter: Run" })
      vim.keymap.set("n", "<leader>FD", "<cmd>FlutterDebug<CR>",         { desc = "Flutter: Debug" })
      vim.keymap.set("n", "<leader>Fs", "<cmd>FlutterRestart<CR>",       { desc = "Flutter: Hot Restart" })
      vim.keymap.set("n", "<leader>FR", "<cmd>FlutterReload<CR>",        { desc = "Flutter: Hot Reload" })
      vim.keymap.set("n", "<leader>Fq", "<cmd>FlutterQuit<CR>",          { desc = "Flutter: Quit" })
      vim.keymap.set("n", "<leader>Fl", function()
        if vim.fn.filereadable(flutter_log_path) == 0 then
          vim.fn.writefile({}, flutter_log_path)
        end
        -- Reuse existing window named flutter-log; open new one only if absent
        local existing = vim.fn.system("tmux select-window -t flutter-log 2>&1")
        if existing:find("no window named") or existing:find("can't find") or existing:find("error") then
          vim.fn.system("tmux new-window -n 'flutter-log' 'tail -f " .. flutter_log_path .. "'")
        end
      end, { desc = "Flutter: Log in tmux pane" })
      vim.keymap.set("n", "<leader>FL", function()
        vim.cmd("FlutterLogClear")
        vim.fn.writefile({}, flutter_log_path)
        -- Kill current tail and restart with a clear screen
        local tail_cmd = "clear && tail -f " .. flutter_log_path
        vim.fn.system("tmux respawn-pane -t flutter-log -k '" .. tail_cmd .. "' 2>/dev/null")
      end, { desc = "Flutter: Clear Log" })
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

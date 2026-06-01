local M = {}

-- { id, label, icon, open(), close(), is_open(), get_win(), get_count?() }
local _panels = {}
local _active_id = nil

local function setup_hl()
  -- Active tab: bold, linked to a bright semantic group (theme-agnostic)
  vim.api.nvim_set_hl(0, "SidebarTabSel", { link = "Function",  default = true })
  -- Inactive tab: muted, no italic
  vim.api.nvim_set_hl(0, "SidebarTabNC",  { link = "Comment",   default = true })
  -- Right-side hint (mode etc.): very subtle
  vim.api.nvim_set_hl(0, "SidebarTabHint",{ link = "NonText",   default = true })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })
setup_hl()

function M.register(panel)
  for _, p in ipairs(_panels) do
    if p.id == panel.id then return end
  end
  table.insert(_panels, panel)
  if not _active_id then _active_id = panel.id end
end

local function find(id)
  for i, p in ipairs(_panels) do
    if p.id == id then return i, p end
  end
  return nil, nil
end

local function active_idx()
  local i = find(_active_id)
  return i or 1
end

function M.tabbar()
  if #_panels == 0 then return "" end

  local parts = {}
  for _, p in ipairs(_panels) do
    local count = (not p.no_badge) and p.get_count and p.get_count()
    local badge = (count and count > 0) and (" (" .. count .. ")") or ""
    local label = p.label .. badge
    if p.id == _active_id then
      table.insert(parts, "%#SidebarTabSel# " .. label .. " %*")
    else
      table.insert(parts, "%#SidebarTabNC# " .. label .. " %*")
    end
  end
  return table.concat(parts, "%#SidebarTabNC#│") .. "%="
end

-- win: window handle; extra: optional right-aligned hint text
function M.set_tabbar(win, extra)
  if not (win and vim.api.nvim_win_is_valid(win)) then return end
  local bar = M.tabbar()
  if extra and extra ~= "" then
    bar = bar .. "%#SidebarTabHint#" .. extra .. " "
  end
  -- suppress all autocmds so plugins (e.g. NvimTree) don't react to the winbar write
  local saved = vim.o.eventignore
  vim.o.eventignore = "all"
  vim.api.nvim_set_option_value("winbar", bar, { win = win })
  vim.o.eventignore = saved
end

function M.switch(id, opts)
  opts = opts or {}
  local focus = opts.focus ~= false
  local _, panel = find(id)
  if not panel then return end

  -- Already on this panel — just focus it, don't re-open
  if panel.is_open() then
    _active_id = id
    local win = panel.get_win and panel.get_win()
    if win then
      M.set_tabbar(win)
      if focus then vim.api.nvim_set_current_win(win) end
    end
    return
  end

  local caller_win = vim.api.nvim_get_current_win()

  -- Collect currently open panels before opening the new one
  local to_close = {}
  for _, p in ipairs(_panels) do
    if p.id ~= id and p.is_open() then
      table.insert(to_close, p)
    end
  end

  -- Open new panel first so there's no gap between panels
  _active_id = id
  panel.open()

  -- Close old panels after new one is visible
  for _, p in ipairs(to_close) do
    p.close()
  end

  vim.schedule(function()
    if _active_id ~= id then return end
    local win = panel.get_win and panel.get_win()
    if win and vim.api.nvim_win_is_valid(win) then
      M.set_tabbar(win)
    end
    if focus then
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
      end
    elseif vim.api.nvim_win_is_valid(caller_win) then
      vim.api.nvim_set_current_win(caller_win)
    end
  end)
end

function M.next()
  local idx = active_idx()
  local next_panel = _panels[(idx % #_panels) + 1]
  if next_panel then M.switch(next_panel.id) end
end

function M.prev()
  local idx = active_idx()
  local prev_panel = _panels[((idx - 2 + #_panels) % #_panels) + 1]
  if prev_panel then M.switch(prev_panel.id) end
end

function M.refresh_tabbar()
  for _, p in ipairs(_panels) do
    if p.is_open() then
      local win = p.get_win and p.get_win()
      if win and vim.api.nvim_win_is_valid(win) then
        M.set_tabbar(win)
      end
    end
  end
end

function M.toggle()
  local _, panel = find(_active_id)
  if panel and panel.is_open() then
    panel.close()
  else
    local id = _active_id or (_panels[1] and _panels[1].id)
    if id then M.switch(id) end
  end
end

function M.resize(delta)
  local win = vim.api.nvim_get_current_win()
  local w = vim.api.nvim_win_get_width(win)
  vim.api.nvim_win_set_width(win, math.max(30, w + delta))
end

function M.setup_keymaps()
  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc })
  end
  map("<leader>1",  function() M.switch("files")  end, "Sidebar: Files")
  map("<leader>2",  function() M.switch("git")    end, "Sidebar: Git")
  map("<leader>3",  function() M.switch("search") end, "Sidebar: Search")
  map("<leader>4",  function() M.switch("marks")  end, "Sidebar: Marks")
  -- map("<leader>4",  function() M.switch("lsp")    end, "Sidebar: LSP")
  -- map("<leader>6",  function() M.switch("github") end, "Sidebar: GitHub")
  map("<leader>ut", function() M.toggle()         end, "Toggle sidebar")
end

return M

local Text = require("control_panel.text")

local Panel = {}

function Panel.new(attrs)
  local p = setmetatable({}, { __index = Panel })

  p._id = attrs.id
  p._title = attrs.title
  p._buf = attrs.buf
  p._tabs_ordered = {}
  p._tabs = {}

  return p
end

local buf
local panels = {}
local win

function Panel:set(tab)
  self._current = tab
  self:render()
end

function Panel:tab(opts)
  local name = opts.name
  local text = Text.new()
  local key = opts.key
  text.padding = 2
  text.wrap = 120

  vim.keymap.set("n", key, function()
    self:set(name)
  end, { buffer = self._buf })

  table.insert(self._tabs_ordered, name)
  self._tabs[name] = { text = text, key = key }

  if self._current == nil then
    self._current = name
  end

  return self
end

function Panel:has_tab(name)
  return not (self._tabs[name] == nil)
end

function Panel:tabs()
  return vim.tbl_keys(self._tabs)
end

function Panel:append(opts)
  local tab = opts.tab
  local text = opts.text
  self._tabs[tab].text:append(text)
  self._tabs[tab].text:nl()

  return self
end

function Panel:render()
  local text = Text.new()

  text.padding = 2
  text.wrap = 120

  text:nl():nl()

  text:append(self._title, "Blue", { wrap = true })

  for _i, tabname in ipairs(self._tabs_ordered) do
    local tab = self._tabs[tabname]
    local hl
    if tabname == self._current then
      hl = "Visual"
    else
      hl = "Normal"
    end

    text:append(" ")
    text:append(" " .. tabname .. " (" .. tab.key .. ") ", hl, { wrap = true })
    text:highlight({ ["%(.%)"] = "@punctuation.special" })
  end

  text:nl():nl()

  local body = text:concat(self._tabs[self._current].text)
  body.padding = 2
  body.wrap = 120

  body:render(self._buf)

  vim.api.nvim_set_current_win(win)

  return self
end

local M = {}

local function new_win()
  local columns = vim.o.columns
  local lines = vim.o.lines
  local width = math.ceil(columns * 0.8)
  local height = math.ceil(lines * 0.8)

  local col = (columns - width) / 2
  local row = ((lines - height) / 2) - 2

  return vim.api.nvim_open_win(buf, true, {
    style = "minimal",
    relative = "win",
    row = row,
    col = col,
    width = width,
    height = height,
  })
end

function M.register(opts)
  local id = opts.id
  local title = opts.title
  buf = vim.api.nvim_create_buf(0, 0)
  panels[id] = Panel.new({
    id = id,
    title = title,
    buf = buf,
  })

  vim.api.nvim_create_user_command("ControlPanel", function(cmdopts)
    local cmd = table.remove(cmdopts.fargs, 1)

    if cmd == "toggle" then
      M.toggle(table.concat(cmdopts.fargs, " "))
    end
  end, { nargs = "*" })
end

function M.toggle(id)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  else
    if not win or not vim.api.nvim_win_is_valid(win) then
      win = new_win()
    end

    panels[id]:render()
  end
end

function M.panel(id)
  return panels[id]
end

return M
